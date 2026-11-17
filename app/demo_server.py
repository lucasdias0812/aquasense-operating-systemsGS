#!/usr/bin/env python3
"""Servidor demonstrativo de infraestrutura AquaSense; NÃO é a API real do grupo."""
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os

PORT = int(os.getenv('APP_PORT', '8080'))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ('/', '/health', '/api/status'):
            self.send_error(404, 'Rota nao encontrada')
            return
        payload = {
            'projeto': 'AquaSense',
            'tipo': 'DEMONSTRACAO DE INFRAESTRUTURA - NAO E A API REAL',
            'status': 'ok',
            'data_utc': datetime.now(timezone.utc).isoformat(),
            'mensagem': 'Servidor Linux e servico AquaSense operacionais.'
        }
        body = json.dumps(payload, ensure_ascii=False, indent=2).encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        print('%s %s' % (self.log_date_time_string(), fmt % args), flush=True)

if __name__ == '__main__':
    ThreadingHTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
