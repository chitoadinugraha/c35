//! Linux FS hooks for WebRTC `remote-fs` (`fs_delegate`).
//!
//! On Linux targets, WebRTC FS uses `c_remote_core::webrtc::fs` natively (see `fs.rs` linux
//! delegate fallback). This registers stub handlers when building the crate on non-Linux hosts.

use c_remote_core::c35_proto::{
    RemoteFsDeleteReq, RemoteFsDeleteRes, RemoteFsListReq, RemoteFsListRes, RemoteFsMkdirReq,
    RemoteFsMkdirRes, RemoteFsReadReq, RemoteFsReadRes, RemoteFsRenameReq, RemoteFsRenameRes,
    RemoteFsWriteReq, RemoteFsWriteRes,
};

fn stub_list(_req: RemoteFsListReq) -> RemoteFsListRes {
    RemoteFsListRes {
        entries: vec![],
        error: "linux fs delegate stub (build host is not Linux)".into(),
    }
}

fn stub_read(_req: RemoteFsReadReq) -> RemoteFsReadRes {
    RemoteFsReadRes {
        data: vec![],
        eof: true,
        mime: String::new(),
        error: "linux fs delegate stub (build host is not Linux)".into(),
    }
}

fn stub_write(_req: RemoteFsWriteReq) -> RemoteFsWriteRes {
    RemoteFsWriteRes {
        bytes_written: 0,
        error: "linux fs delegate stub (build host is not Linux)".into(),
    }
}

fn stub_mkdir(_req: RemoteFsMkdirReq) -> RemoteFsMkdirRes {
    RemoteFsMkdirRes {
        error: "linux fs delegate stub (build host is not Linux)".into(),
    }
}

fn stub_delete(_req: RemoteFsDeleteReq) -> RemoteFsDeleteRes {
    RemoteFsDeleteRes {
        error: "linux fs delegate stub (build host is not Linux)".into(),
    }
}

fn stub_rename(_req: RemoteFsRenameReq) -> RemoteFsRenameRes {
    RemoteFsRenameRes {
        error: "linux fs delegate stub (build host is not Linux)".into(),
    }
}

pub fn register() {
    #[cfg(not(target_os = "linux"))]
    {
        c_remote_core::webrtc::fs_delegate::register_handlers(
            stub_list,
            stub_read,
            stub_write,
            stub_mkdir,
            stub_delete,
            stub_rename,
        );
    }
}
