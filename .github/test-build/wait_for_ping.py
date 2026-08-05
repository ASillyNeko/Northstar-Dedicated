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

with socketserver.TCPServer(("", 7274), Handler) as httpd:
	httpd.handle_request()
