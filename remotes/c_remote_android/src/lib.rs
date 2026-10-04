//! Android Native JNI exports for Alien AI Remote Agent (id.alienai.remote).

pub mod som_overlay;
pub mod webrtc_bridge;

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Mutex, OnceLock};
use jni::objects::{JByteArray, JClass, JObject, JString};
use jni::sys::{jboolean, jint};
use jni::{JNIEnv, JavaVM};
use tracing::info;

static JAVA_VM: OnceLock<JavaVM> = OnceLock::new();
static CALLBACK_OBJ: Mutex<Option<jni::objects::GlobalRef>> = Mutex::new(None);
static RUNTIME: OnceLock<tokio::runtime::Runtime> = OnceLock::new();
static CONTROL_ALLOWED: AtomicBool = AtomicBool::new(true);

fn get_runtime() -> &'static tokio::runtime::Runtime {
    RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .thread_name("alien-remote-rt")
            .build()
            .expect("Failed to initialize tokio runtime for android remote")
    })
}

// ---------------------------------------------------------------------------
// JNI Exports for id.alienai.remote.bridge.NativeBridge
// ---------------------------------------------------------------------------

#[no_mangle]
pub extern "system" fn Java_id_alienai_remote_bridge_NativeBridge_nativeInit(
    mut env: JNIEnv,
    _class: JClass,
    server_url: JString,
    data_dir: JString,
    device_name: JString,
    callback: JObject,
) -> jboolean {
    let _ = tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .try_init();

    if let Ok(vm) = env.get_java_vm() {
        let _ = JAVA_VM.set(vm);
    }

    if let Ok(global_ref) = env.new_global_ref(callback) {
        if let Ok(mut lock) = CALLBACK_OBJ.lock() {
            *lock = Some(global_ref);
        }
    }

    let url_str: String = match env.get_string(&server_url) {
        Ok(s) => s.into(),
        Err(_) => "https://alienai.id".into(),
    };
    let dir_str: String = match env.get_string(&data_dir) {
        Ok(s) => s.into(),
        Err(_) => "/data/data/id.alienai.remote/files".into(),
    };
    let dev_str: String = match env.get_string(&device_name) {
        Ok(s) => s.into(),
        Err(_) => "Android Device".into(),
    };

    info!(url = %url_str, dir = %dir_str, dev = %dev_str, "NativeBridge initializing");

    // Initialize WebRTC and inputs
    webrtc_bridge::init_webrtc_handlers();

    // Wire input events to Java callback
    webrtc_bridge::set_input_callback(Box::new(|evt_type, x, y, text, button, key_code| {
        if !CONTROL_ALLOWED.load(Ordering::SeqCst) {
            return;
        }
        dispatch_input_to_java(&evt_type, x, y, &text, button, key_code);
    }));

    1
}

#[no_mangle]
pub extern "system" fn Java_id_alienai_remote_bridge_NativeBridge_nativePushFrameRgba(
    env: JNIEnv,
    _class: JClass,
    width: jint,
    height: jint,
    rgba_bytes: JByteArray,
) {
    if let Ok(bytes) = env.convert_byte_array(&rgba_bytes) {
        webrtc_bridge::update_frame_buffer(width as u32, height as u32, bytes);
    }
}

#[no_mangle]
pub extern "system" fn Java_id_alienai_remote_bridge_NativeBridge_nativePushFrameH264(
    env: JNIEnv,
    _class: JClass,
    nal_bytes: JByteArray,
    duration_ms: jint,
) {
    if let Ok(bytes) = env.convert_byte_array(&nal_bytes) {
        get_runtime().spawn(async move {
            let _ = webrtc_bridge::push_h264_sample(&bytes, duration_ms as u32).await;
        });
    }
}

#[no_mangle]
pub extern "system" fn Java_id_alienai_remote_bridge_NativeBridge_nativeUpdateMarks(
    mut env: JNIEnv,
    _class: JClass,
    marks_json: JString,
) {
    if let Ok(json_str) = env.get_string(&marks_json) {
        let text: String = json_str.into();
        if let Ok(marks) = serde_json::from_str::<Vec<som_overlay::Mark>>(&text) {
            webrtc_bridge::update_som_marks(marks);
        }
    }
}

#[no_mangle]
pub extern "system" fn Java_id_alienai_remote_bridge_NativeBridge_nativeSetControlAllowed(
    _env: JNIEnv,
    _class: JClass,
    allowed: jboolean,
) {
    CONTROL_ALLOWED.store(allowed != 0, Ordering::SeqCst);
}

#[no_mangle]
pub extern "system" fn Java_id_alienai_remote_bridge_NativeBridge_nativeIsControlAllowed(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    if CONTROL_ALLOWED.load(Ordering::SeqCst) { 1 } else { 0 }
}

#[no_mangle]
pub extern "system" fn Java_id_alienai_remote_bridge_NativeBridge_nativeIsPaired(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    if c_remote_core::config::session_key_load().is_some() { 1 } else { 0 }
}

#[no_mangle]
pub extern "system" fn Java_id_alienai_remote_bridge_NativeBridge_nativeUnpair(
    _env: JNIEnv,
    _class: JClass,
) {
    let _ = c_remote_core::config::session_key_clear();
}

fn dispatch_input_to_java(evt_type: &str, x: f64, y: f64, text: &str, button: i32, key_code: i32) {
    let vm = match JAVA_VM.get() {
        Some(v) => v,
        None => return,
    };
    let guard = match CALLBACK_OBJ.lock() {
        Ok(g) => g,
        Err(_) => return,
    };
    let global_ref = match guard.as_ref() {
        Some(r) => r,
        None => return,
    };

    if let Ok(mut env) = vm.attach_current_thread() {
        let j_type = match env.new_string(evt_type) {
            Ok(s) => s,
            Err(_) => return,
        };
        let j_text = match env.new_string(text) {
            Ok(s) => s,
            Err(_) => return,
        };

        let _ = env.call_method(
            global_ref,
            "onRemoteInput",
            "(Ljava/lang/String;DDLjava/lang/String;II)V",
            &[
                (&j_type).into(),
                x.into(),
                y.into(),
                (&j_text).into(),
                button.into(),
                key_code.into(),
            ],
        );
    }
}
