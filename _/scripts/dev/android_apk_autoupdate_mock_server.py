"""Minimal release server for Android APK OTA integration tests (emulator -> host via 10.0.2.2)."""
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

APK = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
    r"D:\c35\.cache\android-autoupdate-test\app-new.apk"
)
HASH = sys.argv[2] if len(sys.argv) > 2 else ""
PORT = int(sys.argv[3]) if len(sys.argv) > 3 else 8879
VERSION = int(sys.argv[4]) if len(sys.argv) > 4 else 999101

if not APK.is_file():
    raise SystemExit(f"apk not found: {APK}")
if not HASH:
    raise SystemExit(
        "usage: android_apk_autoupdate_mock_server.py <apk> <blake3hex> [port] [version]"
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
        if path == "/version/android":
            payload = {
                "version": VERSION,
                "versionName": "99.999.0",
                "min": 0,
                "url": "https://play.google.com/store/apps/details?id=id.alienai",
                "apkHash": HASH,
                "apkSize": APK.stat().st_size,
                "apkUrl": f"http://10.0.2.2:{PORT}/update.apk",
            }
            body = json.dumps(payload).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/update.apk":
            data = APK.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/vnd.android.package-archive")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        self.send_response(404)
        self.end_headers()

    def log_message(self, fmt, *args):
        print(f"[mock-android-apk] {self.address_string()} {fmt % args}")


if __name__ == "__main__":
    print(f"[mock-android-apk] apk={APK} version={VERSION} port={PORT} apkUrl host=10.0.2.2")
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
