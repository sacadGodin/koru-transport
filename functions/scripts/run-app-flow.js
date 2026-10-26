// Builds "webside koru/tool/flow_check.dart" as a web app, serves it on
// http://localhost:5055 and opens it in headless Chrome. The page runs the
// whole booking flow against the emulators and prints "FLOW OK" or
// "FLOW FAILED" in the browser console, which is read here.
//
// Used by:  npm run test:app   (emulators must be running)
// Chrome:   set CHROME_EXECUTABLE if Chrome is not in /Applications.

const { spawn, execFileSync } = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Emulators not running: refusing to touch the real project.');
  process.exit(1);
}

const site = path.join(__dirname, '..', '..', 'webside koru');
const out = path.join(site, 'build', 'flow_check');
const chrome = process.env.CHROME_EXECUTABLE ||
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 5055;

console.log('Building the flow check web app...');
execFileSync('flutter', ['build', 'web', '-t', 'tool/flow_check.dart',
  '-o', out, '--no-tree-shake-icons'], { cwd: site, stdio: 'inherit' });

const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm',
  '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf',
};
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  let file = path.join(out, url === '/' ? 'index.html' : url);
  if (!file.startsWith(out) || !fs.existsSync(file)) file = path.join(out, 'index.html');
  res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});

server.listen(PORT, () => {
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'koru-flow-'));
  const browser = spawn(chrome, [
    '--headless=new', '--no-first-run', '--no-default-browser-check',
    `--user-data-dir=${profile}`, '--enable-logging=stderr', '--v=0',
    `http://localhost:${PORT}/`,
  ]);

  let result = null;
  const finish = (code) => {
    clearTimeout(timer);
    browser.kill();
    server.close();
    process.exit(code);
  };
  const timer = setTimeout(() => {
    console.error('FLOW FAILED: no result after 3 minutes');
    finish(1);
  }, 3 * 60 * 1000);

  // Console messages look like: ...:INFO:CONSOLE:12] "text", source: ...
  let buffer = '';
  browser.stderr.on('data', (chunk) => {
    buffer += chunk;
    const lines = buffer.split('\n');
    buffer = lines.pop();
    for (const line of lines) {
      const m = line.match(/CONSOLE.*?\] "([\s\S]*)", source:/);
      if (!m) continue;
      const text = m[1].replace(/\\n/g, '\n');
      console.log(`  [app] ${text}`);
      if (text.startsWith('FLOW OK')) result = 0;
      if (text.startsWith('FLOW FAILED')) result = 1;
      if (result !== null) finish(result);
    }
  });
  browser.on('exit', (code) => {
    if (result === null) {
      console.error(`FLOW FAILED: Chrome exited (${code}) before a result`);
      finish(1);
    }
  });
});
