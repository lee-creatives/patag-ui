import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const previewHtmlPath = path.resolve(__dirname, '../preview/Open-PATAG.html');
const PORT = 8080;

const server = http.createServer((req, res) => {
  // Always serve Open-PATAG.html for preview navigation
  fs.readFile(previewHtmlPath, (err, data) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Error loading preview HTML: ' + err.message);
      return;
    }
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-cache'
    });
    res.end(data);
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`PATAG Preview Server running at http://127.0.0.1:${PORT}/`);
});
