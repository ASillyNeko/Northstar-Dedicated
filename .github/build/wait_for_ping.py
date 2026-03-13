import http.server
import socketserver
import sys

class Handler(http.server.SimpleHTTPRequestHandler):
	def do_GET(self):
		self.send_response(200)
		self.end_headers()
		sys.exit(0)

with socketserver.TCPServer(("", 7274), Handler) as httpd:
	httpd.handle_request()