//! Wayland emulated input via libei (`reis` crate).

use c_remote_core::c35_proto::RemoteInputEvent;
use enumflags2::{BitFlags, make_bitflags};
use reis::ei::button::ButtonState;
use reis::ei::handshake::ContextType;
use reis::ei::keyboard::KeyState;
use reis::ei::{
    button::Button as EiButton,
    device::Device as EiDevice,
    keyboard::Keyboard,
    pointer_absolute::PointerAbsolute,
    scroll::Scroll,
    text::Text,
    Context,
};
use reis::event::{Device as HlDevice, DeviceCapability, EiEvent, Seat};
use reis::Interface;
use std::sync::Mutex;
use tracing::{info, warn};

use super::shared::{apply_staged_update, evdev_button, monotonic_us, pixel_coords, vk_to_evdev};

struct DeviceHandles {
    hl: HlDevice,
    pointer: Option<PointerAbsolute>,
    button: Option<EiButton>,
    keyboard: Option<Keyboard>,
    scroll: Option<Scroll>,
    text: Option<Text>,
}

struct LibeiSession {
    context: Context,
    devices: Vec<DeviceHandles>,
    events: reis::event::EiConvertEventIterator,
    last_serial: u32,
    emulate_seq: u32,
    emulating: bool,
}

static SESSION: Mutex<Option<LibeiSession>> = Mutex::new(None);

fn desired_capabilities() -> BitFlags<DeviceCapability> {
    make_bitflags!(DeviceCapability::{
        PointerAbsolute,
        Button,
        Keyboard,
        Scroll,
        Text
    })
}

fn collect_interfaces(device: &HlDevice) -> DeviceHandles {
    DeviceHandles {
        hl: device.clone(),
        pointer: device.interface::<PointerAbsolute>(),
        button: device.interface::<EiButton>(),
        keyboard: device.interface::<Keyboard>(),
        scroll: device.interface::<Scroll>(),
        text: device.interface::<Text>(),
    }
}

fn device_usable(handles: &DeviceHandles) -> bool {
    handles.pointer.is_some()
        && handles.button.is_some()
        && (handles.keyboard.is_some() || handles.text.is_some())
}

fn pump_events(session: &mut LibeiSession) {
    while let Some(event) = session.events.next() {
        match event {
            EiEvent::SeatAdded(seat_added) => {
                seat_added
                    .seat
                    .bind_capabilities(desired_capabilities());
            }
            EiEvent::DeviceAdded(added) => {
                let ei_dev = added.device.device();
                if ei_dev.version() >= 3 {
                    ei_dev.ready();
                }
                let handles = collect_interfaces(&added.device);
                if device_usable(&handles) {
                    session.devices.push(handles);
                }
            }
            EiEvent::DeviceResumed(resumed) => {
                session.last_serial = resumed.serial;
                let ei_dev = resumed.device.device();
                if !session.emulating {
                    ei_dev.start_emulating(session.last_serial, session.emulate_seq);
                    session.emulate_seq += 1;
                    session.emulating = true;
                }
            }
            EiEvent::Frame(frame) => {
                session.last_serial = frame.serial;
            }
            EiEvent::Disconnected(_) => {
                warn!("libei connection closed by compositor");
                session.devices.clear();
                session.emulating = false;
            }
            _ => {}
        }
    }
}

fn connect() -> Option<LibeiSession> {
    let context = match Context::connect_to_env() {
        Ok(Some(ctx)) => ctx,
        Ok(None) => {
            warn!(
                "libei unavailable: LIBEI_SOCKET not set (grant Remote Desktop / input portal first)"
            );
            return None;
        }
        Err(e) => {
            warn!("libei connect failed: {e}");
            return None;
        }
    };

    let (_connection, events) = match context.handshake_blocking(
        "c_remote_linux",
        ContextType::Sender,
    ) {
        Ok(pair) => pair,
        Err(e) => {
            warn!("libei handshake failed: {e}");
            return None;
        }
    };

    let mut session = LibeiSession {
        context,
        devices: Vec::new(),
        events,
        last_serial: 0,
        emulate_seq: 1,
        emulating: false,
    };

    pump_events(&mut session);
    if session.devices.is_empty() {
        warn!("libei connected but no emulated input device is ready");
        return None;
    }
    info!(devices = session.devices.len(), "libei input session ready");
    Some(session)
}

fn ensure_session() -> bool {
    let mut guard = SESSION.lock().unwrap_or_else(|e| e.into_inner());
    if guard.is_none() {
        *guard = connect();
    }
    guard.is_some()
}

fn ensure_emulating(session: &mut LibeiSession, dev: &DeviceHandles) {
    if session.emulating {
        return;
    }
    dev.hl.device().start_emulating(session.last_serial, session.emulate_seq);
    session.emulate_seq += 1;
    session.emulating = true;
}

fn end_frame(session: &mut LibeiSession, dev: &DeviceHandles) {
    let ei_dev: &EiDevice = dev.hl.device();
    ei_dev.frame(session.last_serial, monotonic_us());
    let _ = session.context.flush();
    pump_events(session);
}

fn dispatch(session: &mut LibeiSession, evt: &RemoteInputEvent) {
    pump_events(session);
    let Some(dev) = session.devices.first() else {
        return;
    };
    let dev = dev.clone();
    ensure_emulating(session, &dev);

    let (px, py) = pixel_coords(evt);

    match evt.event_type.as_str() {
        "mouse_move" => {
            if let Some(pointer) = dev.pointer.as_ref() {
                pointer.motion_absolute(px as f32, py as f32);
            }
            end_frame(session, &dev);
        }
        "mouse_down" => {
            if let Some(pointer) = dev.pointer.as_ref() {
                pointer.motion_absolute(px as f32, py as f32);
            }
            if let Some(btn) = dev.button.as_ref() {
                btn.button(evdev_button(&evt.button), ButtonState::Press);
            }
            end_frame(session, &dev);
        }
        "mouse_up" => {
            if let Some(pointer) = dev.pointer.as_ref() {
                pointer.motion_absolute(px as f32, py as f32);
            }
            if let Some(btn) = dev.button.as_ref() {
                btn.button(evdev_button(&evt.button), ButtonState::Released);
            }
            end_frame(session, &dev);
        }
        "mouse_click" | "double_click" | "triple_click" => {
            let clicks = match evt.event_type.as_str() {
                "double_click" => 2,
                "triple_click" => 3,
                _ => 1,
            };
            if let Some(pointer) = dev.pointer.as_ref() {
                pointer.motion_absolute(px as f32, py as f32);
            }
            if let Some(btn) = dev.button.as_ref() {
                let code = evdev_button(&evt.button);
                for _ in 0..clicks {
                    btn.button(code, ButtonState::Press);
                    btn.button(code, ButtonState::Released);
                }
            }
            end_frame(session, &dev);
        }
        "right_click" => {
            if let Some(pointer) = dev.pointer.as_ref() {
                pointer.motion_absolute(px as f32, py as f32);
            }
            if let Some(btn) = dev.button.as_ref() {
                let code = evdev_button("right");
                btn.button(code, ButtonState::Press);
                btn.button(code, ButtonState::Released);
            }
            end_frame(session, &dev);
        }
        "middle_click" => {
            if let Some(pointer) = dev.pointer.as_ref() {
                pointer.motion_absolute(px as f32, py as f32);
            }
            if let Some(btn) = dev.button.as_ref() {
                let code = evdev_button("middle");
                btn.button(code, ButtonState::Press);
                btn.button(code, ButtonState::Released);
            }
            end_frame(session, &dev);
        }
        "wheel" => {
            if let Some(scroll) = dev.scroll.as_ref() {
                let dy = (evt.delta_y * 120.0).round() as i32;
                scroll.scroll_discrete(0, dy);
            }
            end_frame(session, &dev);
        }
        "key_down" => {
            if let Some(key) = vk_to_evdev(evt.key_code) {
                if let Some(kbd) = dev.keyboard.as_ref() {
                    kbd.key(key, KeyState::Press);
                }
            } else if let Some(text) = dev.text.as_ref() {
                let ch = evt.text.chars().next().unwrap_or_default();
                if !ch.is_empty() {
                    text.utf8(&ch.to_string());
                }
            }
            end_frame(session, &dev);
        }
        "key_up" => {
            if let Some(key) = vk_to_evdev(evt.key_code) {
                if let Some(kbd) = dev.keyboard.as_ref() {
                    kbd.key(key, KeyState::Released);
                }
            }
            end_frame(session, &dev);
        }
        "type_text" => {
            if !evt.text.is_empty() {
                if let Some(text) = dev.text.as_ref() {
                    let chunk = if evt.text.len() > 254 {
                        evt.text.chars().take(254).collect::<String>()
                    } else {
                        evt.text.clone()
                    };
                    text.utf8(&chunk);
                }
            }
            end_frame(session, &dev);
        }
        other => info!(event_type = other, "unhandled remote input event on Linux (libei)"),
    }
}

/// Returns true if the event was handled (or intentionally dropped after a live libei session).
pub fn try_execute(evt: &RemoteInputEvent) -> bool {
    if evt.event_type.as_str() == "apply_update" {
        apply_staged_update();
        return true;
    }

    if !ensure_session() {
        return false;
    }

    let mut guard = SESSION.lock().unwrap_or_else(|e| e.into_inner());
    if let Some(session) = guard.as_mut() {
        dispatch(session, evt);
        return true;
    }
    false
}
