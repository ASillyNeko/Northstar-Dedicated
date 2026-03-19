import http.server
import socketserver
import os
import subprocess
import threading
import time

class Handler(http.server.SimpleHTTPRequestHandler):
	def do_GET(self):
		self.send_response(200)
		self.end_headers()

def is_container_running():
	result = subprocess.run(
		["docker", "compose", "ps", "--status", "running", "-q"],
		capture_output=True, text=True
	)

	return result.stdout.strip() != ""

def watch_container():
	while True:
		if not is_container_running():
			print("Container exited.")

			os._exit(1)

		time.sleep(1)

watcher = threading.Thread(target=watch_container, daemon=True)
watcher.start()

with socketserver.TCPServer(("", 7274), Handler) as httpd:
	httpd.handle_request()