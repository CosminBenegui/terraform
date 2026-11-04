#!/usr/bin/env python3
"""Harborline shipping API. Bind address and token come from the environment."""

import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

EXPECTED_TOKEN = "harborline-ship-ok"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path != "/health":
            self.send_response(404)
            self.end_headers()
            return
        token = os.environ.get("API_TOKEN", "")
        if token != EXPECTED_TOKEN:
            body = b"bad token\n"
            self.send_response(503)
        else:
            body = b"ok\n"
            self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        return


def main():
    bind = os.environ["API_BIND"]
    host, port = bind.rsplit(":", 1)
    ThreadingHTTPServer((host, int(port)), Handler).serve_forever()


if __name__ == "__main__":
    main()
