import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../dist');
const port = 8090;

const files = new Map([
  ['/PATAG-Citizen-v1.0.0.apk', 'PATAG-Citizen-v1.0.0.apk'],
  ['/PATAG-Maintenance-v1.0.0.apk', 'PATAG-Maintenance-v1.0.0.apk'],
]);

const server = http.createServer((request, response) => {
  const url = new URL(request.url ?? '/', `http://127.0.0.1:${port}`);
  const fileName = files.get(url.pathname);

  if (!fileName) {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('APK not found.');
    return;
  }

  const filePath = path.join(root, fileName);
  fs.stat(filePath, (statError, stats) => {
    if (statError || !stats.isFile()) {
      response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('APK not found.');
      return;
    }

    response.writeHead(200, {
      'Content-Type': 'application/vnd.android.package-archive',
      'Content-Length': stats.size,
      'Content-Disposition': `attachment; filename="${fileName}"`,
      'Cache-Control': 'no-store',
    });
    fs.createReadStream(filePath).pipe(response);
  });
});

server.listen(port, '127.0.0.1', () => {
  console.log(`APK downloads available at http://127.0.0.1:${port}/`);
});
