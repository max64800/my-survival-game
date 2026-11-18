import { test } from 'node:test';
import assert from 'node:assert/strict';

import { mask } from '../detector/lib/mask.js';
import { detect } from '../detector/index.js';

test('masking preserves length and line breaks', () => {
  const text = 'first\n`code here`\nlast\n';
  const masked = mask(text);
  assert.equal(masked.length, text.length);
  assert.equal(masked.split('\n').length, text.split('\n').length);
});

test('fenced code is not linted', () => {
  const text = 'Обычный текст.\n\n```js\nconst delve = "В современном мире";\n```\n';
  assert.deepEqual(detect(text, { lang: 'ru' }).issues, []);
});

test('inline code is not linted', () => {
  assert.deepEqual(detect('Функция `является` возвращает true.', { lang: 'ru' }).issues, []);
});

test('blockquotes are not linted — quoted text belongs to whoever said it', () => {
  assert.deepEqual(detect('> В современном мире всё меняется.\n', { lang: 'ru' }).issues, []);
});

test('frontmatter is not linted', () => {
  const text = '---\ndescription: In today\'s digital landscape\n---\n\nPlain sentence here.\n';
  assert.deepEqual(detect(text, { lang: 'en' }).issues, []);
});

test('link targets are masked but link text is not', () => {
  const withUrl = 'See [the docs](https://example.com/delve-into-things) for details.';
  assert.deepEqual(detect(withUrl, { lang: 'en' }).issues, []);
  const withText = 'See [delve into things](https://example.com/x) for details.';
  assert.equal(detect(withText, { lang: 'en' }).issues.length, 1);
});

test('positions still point at the original text after masking', () => {
  const text = '```\nignored\n```\n\nВ современном мире всё меняется.\n';
  const [issue] = detect(text, { lang: 'ru' }).issues;
  assert.equal(issue.line, 5);
  assert.equal(issue.column, 1);
});
