//! Platform FS hooks (Android agent registers JNI-backed handlers at startup).

use std::sync::OnceLock;

use c35_proto::{
    RemoteFsDeleteReq, RemoteFsDeleteRes, RemoteFsListReq, RemoteFsListRes, RemoteFsMkdirReq,
    RemoteFsMkdirRes, RemoteFsReadReq, RemoteFsReadRes, RemoteFsRenameReq, RemoteFsRenameRes,
    RemoteFsWriteReq, RemoteFsWriteRes,
};

type FsListFn = fn(RemoteFsListReq) -> RemoteFsListRes;
type FsReadFn = fn(RemoteFsReadReq) -> RemoteFsReadRes;
type FsWriteFn = fn(RemoteFsWriteReq) -> RemoteFsWriteRes;
type FsMkdirFn = fn(RemoteFsMkdirReq) -> RemoteFsMkdirRes;
type FsDeleteFn = fn(RemoteFsDeleteReq) -> RemoteFsDeleteRes;
type FsRenameFn = fn(RemoteFsRenameReq) -> RemoteFsRenameRes;

struct Handlers {
    list: FsListFn,
    read: FsReadFn,
    write: FsWriteFn,
    mkdir: FsMkdirFn,
    delete: FsDeleteFn,
    rename: FsRenameFn,
}

static HANDLERS: OnceLock<Handlers> = OnceLock::new();

pub fn register_handlers(
    list: FsListFn,
    read: FsReadFn,
    write: FsWriteFn,
    mkdir: FsMkdirFn,
    delete: FsDeleteFn,
    rename: FsRenameFn,
) {
    let _ = HANDLERS.set(Handlers {
        list,
        read,
        write,
        mkdir,
        delete,
        rename,
    });
}

pub fn is_registered() -> bool {
    HANDLERS.get().is_some()
}

pub fn dispatch_list(req: RemoteFsListReq) -> Option<RemoteFsListRes> {
    HANDLERS.get().map(|h| (h.list)(req))
}

pub fn dispatch_read(req: RemoteFsReadReq) -> Option<RemoteFsReadRes> {
    HANDLERS.get().map(|h| (h.read)(req))
}

pub fn dispatch_write(req: RemoteFsWriteReq) -> Option<RemoteFsWriteRes> {
    HANDLERS.get().map(|h| (h.write)(req))
}

pub fn dispatch_mkdir(req: RemoteFsMkdirReq) -> Option<RemoteFsMkdirRes> {
    HANDLERS.get().map(|h| (h.mkdir)(req))
}

pub fn dispatch_delete(req: RemoteFsDeleteReq) -> Option<RemoteFsDeleteRes> {
    HANDLERS.get().map(|h| (h.delete)(req))
}

pub fn dispatch_rename(req: RemoteFsRenameReq) -> Option<RemoteFsRenameRes> {
    HANDLERS.get().map(|h| (h.rename)(req))
}

pub fn not_ready_list() -> RemoteFsListRes {
    RemoteFsListRes {
        entries: vec![],
        error: "android storage bridge not ready".into(),
    }
}

pub fn not_ready_read() -> RemoteFsReadRes {
    RemoteFsReadRes {
        data: vec![],
        eof: true,
        mime: String::new(),
        error: "android storage bridge not ready".into(),
    }
}

pub fn not_ready_write() -> RemoteFsWriteRes {
    RemoteFsWriteRes {
        bytes_written: 0,
        error: "android storage bridge not ready".into(),
    }
}

pub fn not_ready_mkdir() -> RemoteFsMkdirRes {
    RemoteFsMkdirRes {
        error: "android storage bridge not ready".into(),
    }
}

pub fn not_ready_delete() -> RemoteFsDeleteRes {
    RemoteFsDeleteRes {
        error: "android storage bridge not ready".into(),
    }
}

pub fn not_ready_rename() -> RemoteFsRenameRes {
    RemoteFsRenameRes {
        error: "android storage bridge not ready".into(),
    }
}
