"""Minimal release server for Windows desktop app OTA integration tests."""
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

ZIP = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
    r"D:\c35\.cache\windows-autoupdate-test\alienai-windows-fixture.zip"
)
HASH = sys.argv[2] if len(sys.argv) > 2 else ""
PORT = int(sys.argv[3]) if len(sys.argv) > 3 else 8878
VERSION = int(sys.argv[4]) if len(sys.argv) > 4 else 999001

if not ZIP.is_file():
    raise SystemExit(f"zip not found: {ZIP}")
if not HASH:
    raise SystemExit(
        "usage: windows_app_autoupdate_mock_server.py <zip> <blake3hex> [port] [version]"
    )


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/livez":
            body = b"ok"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/version/windows":
            payload = {
                "version": VERSION,
                "versionName": "99.999.0",
                "min": 0,
                "hash": HASH,
                "size": ZIP.stat().st_size,
                "url": f"http://127.0.0.1:{PORT}/bundle.zip",
            }
            body = json.dumps(payload).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/bundle.zip":
            data = ZIP.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/zip")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        self.send_response(404)
        self.end_headers()

    def log_message(self, fmt, *args):
        print(f"[mock-windows-app] {self.address_string()} {fmt % args}")


if __name__ == "__main__":
    print(f"[mock-windows-app] zip={ZIP} version={VERSION} port={PORT}")
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()