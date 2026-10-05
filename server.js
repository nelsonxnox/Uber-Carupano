const http = require('http');
const fs = require('fs');
const path = require('path');
const base = 'D:\\carupano_riders\\build\\web';

const mime = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf'
};

http.createServer((req, res) => {
  let file = path.join(base, req.url === '/' ? 'index.html' : req.url.split('?')[0]);
  if (!fs.existsSync(file)) file = path.join(base, 'index.html');
  const ext = path.extname(file);
  res.writeHead(200, {
    'Content-Type': mime[ext] || 'application/octet-stream',
    'Access-Control-Allow-Origin': '*',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
  });
  fs.createReadStream(file).pipe(res);
}).listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});