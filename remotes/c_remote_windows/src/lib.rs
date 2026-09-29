pub mod audio_capture;
pub mod cursor_shape;
pub mod dxgi_capture;
pub mod icon;
pub mod input_exec;
pub mod pair_loop;
pub mod pair_ui;
pub mod pair_window;
pub mod screen_capture;
pub mod startup;
pub mod agent_window;
#[cfg(windows)]
pub mod agent_status_window;
#[cfg(windows)]
pub mod agent_window_ui;
pub mod drive;
pub mod tray;
pub mod uia;
pub mod video_stream;
#[cfg(windows)]
pub mod skill_teach_hook;
#[cfg(windows)]
pub mod skill_teach_overlay;
#[cfg(windows)]
pub mod skill_teach_platform;
#[cfg(windows)]
pub mod skill_teach_remote;
