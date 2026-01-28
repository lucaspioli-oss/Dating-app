const fs = require('fs');
const content = require('fs').readFileSync('src/pages/Sales2.tsx', 'utf8');
console.log('Current file length:', content.length);
