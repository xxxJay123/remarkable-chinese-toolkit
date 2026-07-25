const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const htmlPath = path.join(__dirname, '..', 'src', 'index.html');
const html = fs.readFileSync(htmlPath, 'utf8');
const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/gi)];

if (scripts.length !== 1) {
  throw new Error(`Expected one inline renderer script, found ${scripts.length}`);
}

new vm.Script(scripts[0][1], { filename: htmlPath });
console.log('Renderer script syntax is valid.');
