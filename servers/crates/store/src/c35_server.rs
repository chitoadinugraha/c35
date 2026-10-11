//! Default HTTP port for `server_ai` / `c35-server`.
//!
//! Keep in sync with `clients/app/lib/c/conn/server_host_port.dart` and
//! `_/scripts/dev/c35_server_port.ps1`.

pub const HTTP_PORT: u16 = 10000;

pub const LISTEN_DEFAULT: &str = "0.0.0.0:10000";

pub const CLUSTER_BASE_URL: &str = "http://c35-server.c35.svc.cluster.local:10000";

pub const LOCAL_BASE_URL: &str = "http://127.0.0.1:10000";
