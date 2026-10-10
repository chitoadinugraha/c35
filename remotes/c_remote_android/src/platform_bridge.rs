//! JNI bridges for Android FS + shell (`c_remote_core` delegates).

use base64::Engine;
use c_remote_core::c35_proto::{
    RemoteFsDeleteReq, RemoteFsDeleteRes, RemoteFsEntry, RemoteFsListReq, RemoteFsListRes,
    RemoteFsMkdirReq, RemoteFsMkdirRes, RemoteFsReadReq, RemoteFsReadRes, RemoteFsRenameReq,
    RemoteFsRenameRes, RemoteFsWriteReq, RemoteFsWriteRes,
};
use c_remote_core::shell_delegate::ShellOutput;

use crate::JAVA_VM;

fn parse_list_json(json: &str) -> RemoteFsListRes {
    let v: serde_json::Value = serde_json::from_str(json).unwrap_or(serde_json::json!({}));
    let error = v.get("error").and_then(|e| e.as_str()).unwrap_or("").to_string();
    let mut entries = Vec::new();
    if let Some(arr) = v.get("entries").and_then(|a| a.as_array()) {
        for e in arr {
            entries.push(RemoteFsEntry {
                name: e.get("name").and_then(|x| x.as_str()).unwrap_or("").into(),
                path: e.get("path").and_then(|x| x.as_str()).unwrap_or("").into(),
                is_dir: e.get("is_dir").and_then(|x| x.as_bool()).unwrap_or(false),
                size: e.get("size").and_then(|x| x.as_i64()).unwrap_or(0),
                modified_ms: e.get("modified_ms").and_then(|x| x.as_i64()).unwrap_or(0),
                drive_kind: 0,
            });
        }
    }
    RemoteFsListRes { entries, error }
}

fn parse_read_json(json: &str) -> RemoteFsReadRes {
    let v: serde_json::Value = serde_json::from_str(json).unwrap_or(serde_json::json!({}));
    RemoteFsReadRes {
        data: v
            .get("data_b64")
            .and_then(|x| x.as_str())
            .and_then(|s| base64::engine::general_purpose::STANDARD.decode(s).ok())
            .unwrap_or_default(),
        eof: v.get("eof").and_then(|x| x.as_bool()).unwrap_or(true),
        mime: v.get("mime").and_then(|x| x.as_str()).unwrap_or("").into(),
        error: v.get("error").and_then(|x| x.as_str()).unwrap_or("").into(),
    }
}

fn parse_write_json(json: &str) -> RemoteFsWriteRes {
    let v: serde_json::Value = serde_json::from_str(json).unwrap_or(serde_json::json!({}));
    RemoteFsWriteRes {
        bytes_written: v.get("bytes_written").and_then(|x| x.as_i64()).unwrap_or(0),
        error: v.get("error").and_then(|x| x.as_str()).unwrap_or("parse error").into(),
    }
}

fn parse_simple_json(json: &str) -> String {
    let v: serde_json::Value = serde_json::from_str(json).unwrap_or(serde_json::json!({}));
    v.get("error").and_then(|e| e.as_str()).unwrap_or("").to_string()
}

fn jstring_result(
    env: &mut jni::JNIEnv,
    call: Result<jni::objects::JObject, jni::errors::Error>,
) -> String {
    match call {
        Ok(j) => {
            if j.is_null() {
                return "{\"error\":\"jni null\"}".into();
            }
            let js = jni::objects::JString::from(j);
            env.get_string(&js)
                .map(|s| s.into())
                .unwrap_or_else(|_| "{\"error\":\"utf8\"}".into())
        }
        Err(_) => "{\"error\":\"jni\"}".into(),
    }
}

fn fs_list_impl(req: RemoteFsListReq) -> RemoteFsListRes {
    let vm = JAVA_VM.get();
    if vm.is_none() {
        return c_remote_core::webrtc::fs_delegate::not_ready_list();
    }
    let mut env = match vm.unwrap().attach_current_thread() {
        Ok(e) => e,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_list(),
    };
    let jpath = match env.new_string(&req.path) {
        Ok(p) => p,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_list(),
    };
    let call = env
        .call_static_method(
            "id/alienai/remote/bridge/RemoteStorageBridge",
            "fsList",
            "(Ljava/lang/String;)Ljava/lang/String;",
            &[(&jpath).into()],
        )
        .and_then(|v| v.l());
    let json = jstring_result(&mut env, call);
    parse_list_json(&json)
}

fn fs_read_impl(req: RemoteFsReadReq) -> RemoteFsReadRes {
    let vm = JAVA_VM.get();
    if vm.is_none() {
        return c_remote_core::webrtc::fs_delegate::not_ready_read();
    }
    let mut env = match vm.unwrap().attach_current_thread() {
        Ok(e) => e,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_read(),
    };
    let jpath = match env.new_string(&req.path) {
        Ok(p) => p,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_read(),
    };
    let call = env
        .call_static_method(
            "id/alienai/remote/bridge/RemoteStorageBridge",
            "fsRead",
            "(Ljava/lang/String;JI)Ljava/lang/String;",
            &[
                (&jpath).into(),
                (req.offset as i64).into(),
                (req.length as i32).into(),
            ],
        )
        .and_then(|v| v.l());
    let json = jstring_result(&mut env, call);
    parse_read_json(&json)
}

fn fs_write_impl(req: RemoteFsWriteReq) -> RemoteFsWriteRes {
    let vm = JAVA_VM.get();
    if vm.is_none() {
        return c_remote_core::webrtc::fs_delegate::not_ready_write();
    }
    let mut env = match vm.unwrap().attach_current_thread() {
        Ok(e) => e,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_write(),
    };
    let jpath = match env.new_string(&req.path) {
        Ok(p) => p,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_write(),
    };
    let jdata = match env.byte_array_from_slice(&req.data) {
        Ok(d) => d,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_write(),
    };
    let call = env
        .call_static_method(
            "id/alienai/remote/bridge/RemoteStorageBridge",
            "fsWrite",
            "(Ljava/lang/String;J[BZ)Ljava/lang/String;",
            &[
                (&jpath).into(),
                (req.offset as i64).into(),
                (&jdata).into(),
                (if req.finalize { 1i32 } else { 0i32 }).into(),
            ],
        )
        .and_then(|v| v.l());
    let json = jstring_result(&mut env, call);
    parse_write_json(&json)
}

fn fs_mkdir_impl(req: RemoteFsMkdirReq) -> RemoteFsMkdirRes {
    let vm = JAVA_VM.get();
    if vm.is_none() {
        return c_remote_core::webrtc::fs_delegate::not_ready_mkdir();
    }
    let mut env = match vm.unwrap().attach_current_thread() {
        Ok(e) => e,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_mkdir(),
    };
    let jpath = match env.new_string(&req.path) {
        Ok(p) => p,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_mkdir(),
    };
    let call = env
        .call_static_method(
            "id/alienai/remote/bridge/RemoteStorageBridge",
            "fsMkdir",
            "(Ljava/lang/String;)Ljava/lang/String;",
            &[(&jpath).into()],
        )
        .and_then(|v| v.l());
    let json = jstring_result(&mut env, call);
    RemoteFsMkdirRes {
        error: parse_simple_json(&json),
    }
}

fn fs_delete_impl(req: RemoteFsDeleteReq) -> RemoteFsDeleteRes {
    let vm = JAVA_VM.get();
    if vm.is_none() {
        return c_remote_core::webrtc::fs_delegate::not_ready_delete();
    }
    let mut env = match vm.unwrap().attach_current_thread() {
        Ok(e) => e,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_delete(),
    };
    let jpath = match env.new_string(&req.path) {
        Ok(p) => p,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_delete(),
    };
    let call = env
        .call_static_method(
            "id/alienai/remote/bridge/RemoteStorageBridge",
            "fsDelete",
            "(Ljava/lang/String;)Ljava/lang/String;",
            &[(&jpath).into()],
        )
        .and_then(|v| v.l());
    let json = jstring_result(&mut env, call);
    RemoteFsDeleteRes {
        error: parse_simple_json(&json),
    }
}

fn fs_rename_impl(req: RemoteFsRenameReq) -> RemoteFsRenameRes {
    let vm = JAVA_VM.get();
    if vm.is_none() {
        return c_remote_core::webrtc::fs_delegate::not_ready_rename();
    }
    let mut env = match vm.unwrap().attach_current_thread() {
        Ok(e) => e,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_rename(),
    };
    let jfrom = match env.new_string(&req.from_path) {
        Ok(p) => p,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_rename(),
    };
    let jto = match env.new_string(&req.to_path) {
        Ok(p) => p,
        Err(_) => return c_remote_core::webrtc::fs_delegate::not_ready_rename(),
    };
    let call = env
        .call_static_method(
            "id/alienai/remote/bridge/RemoteStorageBridge",
            "fsRename",
            "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;",
            &[(&jfrom).into(), (&jto).into()],
        )
        .and_then(|v| v.l());
    let json = jstring_result(&mut env, call);
    RemoteFsRenameRes {
        error: parse_simple_json(&json),
    }
}

fn shell_impl(command: &str, timeout_secs: u32) -> ShellOutput {
    let vm = JAVA_VM.get();
    if vm.is_none() {
        return c_remote_core::shell_delegate::not_supported(command);
    }
    let mut env = match vm.unwrap().attach_current_thread() {
        Ok(e) => e,
        Err(_) => return c_remote_core::shell_delegate::not_supported(command),
    };
    let jcmd = match env.new_string(command) {
        Ok(c) => c,
        Err(_) => return c_remote_core::shell_delegate::not_supported(command),
    };
    let call = env
        .call_static_method(
            "id/alienai/remote/bridge/RemoteShellBridge",
            "run",
            "(Ljava/lang/String;I)Ljava/lang/String;",
            &[(&jcmd).into(), (timeout_secs as i32).into()],
        )
        .and_then(|v| v.l());
    let json = jstring_result(&mut env, call);
    let v: serde_json::Value = serde_json::from_str(&json).unwrap_or(serde_json::json!({}));
    ShellOutput {
        ok: v.get("ok").and_then(|x| x.as_bool()).unwrap_or(false),
        exit_code: v.get("exit_code").and_then(|x| x.as_i64()).unwrap_or(-1) as i32,
        stdout: v
            .get("stdout")
            .and_then(|x| x.as_str())
            .unwrap_or("")
            .to_string(),
        stderr: v
            .get("stderr")
            .and_then(|x| x.as_str())
            .unwrap_or("")
            .to_string(),
        error: v.get("error").and_then(|x| x.as_str()).unwrap_or("").to_string(),
    }
}

pub fn register_platform_handlers() {
    c_remote_core::webrtc::fs_delegate::register_handlers(
        fs_list_impl,
        fs_read_impl,
        fs_write_impl,
        fs_mkdir_impl,
        fs_delete_impl,
        fs_rename_impl,
    );
    c_remote_core::shell_delegate::register_shell(shell_impl);
    c_remote_core::android_shell::set_shell_handler(shell_impl);
}

pub fn storage_grant_count() -> i32 {
    let vm = JAVA_VM.get();
    if vm.is_none() {
        return 0;
    }
    let mut env = match vm.unwrap().attach_current_thread() {
        Ok(e) => e,
        Err(_) => return 0,
    };
    match env.call_static_method(
        "id/alienai/remote/bridge/RemoteStorageBridge",
        "grantCount",
        "()I",
        &[],
    ) {
        Ok(v) => v.i().unwrap_or(0),
        Err(_) => 0,
    }
}
