/// Default `server_ai` HTTP port.
///
/// Keep in sync with `c35_store::c35_server` and `_/scripts/dev/c35_server_port.ps1`.
const c35ServerHttpPort = 10000;

String c35ServerHttpUrl(String host) => 'http://$host:$c35ServerHttpPort';
