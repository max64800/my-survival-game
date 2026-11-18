import { test } from 'node:test';
import assert from 'node:assert/strict';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { parseBanned } from '../detector/lib/parse-banned.js';
import { buildMatcher } from '../detector/lib/morphology.js';

const REFERENCES = new URL('../references/', import.meta.url);

function fixture(contents) {
  const dir = mkdtempSync(join(tmpdir(), 'aislop-'));
  const file = join(dir, 'banned.md');
  writeFileSync(file, contents, 'utf8');
  return file;
}

function patterns(entries) {
  return entries.map((e) => e.pattern);
}

test('splits slash variants into separate patterns', () => {
  const file = fixture('# t\n\n## Banned Vocabulary\n\ndelve / delves / delving, tapestry\n');
  const { entries } = parseBanned(file, 'en');
  assert.deepEqual(patterns(entries), ['delve', 'delves', 'delving', 'tapestry']);
  assert.equal(entries.every((e) => e.severity === 'high'), true);
});

test('an arrow in brackets becomes the suggested fix', () => {
  const file = fixture('# t\n\n## Запрещённая лексика\n\nКанцелярит: данный (→ этот), является (→ это / есть)\n');
  const { entries } = parseBanned(file, 'ru');
  const dannyi = entries.find((e) => e.pattern === 'данный');
  assert.equal(dannyi.fix, 'этот');
  assert.equal(dannyi.category, 'Канцелярит');
  assert.equal(dannyi.severity, 'medium');
});

test('a quoted example built from the term replaces the bare word', () => {
  const file = fixture('# t\n\n## Запрещённая лексика\n\nэпоха («в эпоху»), ландшафт (переносное: «информационный ландшафт»)\n');
  const { entries } = parseBanned(file, 'ru');
  assert.deepEqual(patterns(entries), ['в эпоху', 'информационный ландшафт']);
});

test('a quoted gloss does not become a pattern', () => {
  // «производить (в значении «делать»)» must not ban the ordinary word «делать»
  const file = fixture('# t\n\n## Запрещённая лексика\n\nпроизводить (в значении «делать»)\n');
  const { entries } = parseBanned(file, 'ru');
  assert.deepEqual(patterns(entries), ['производить']);
  assert.equal(entries[0].severity, 'low');
});

test('an unverifiable condition lowers severity', () => {
  const file = fixture('# t\n\n## Banned Vocabulary\n\nlandscape (figurative), robust (outside engineering), tapestry\n');
  const { entries } = parseBanned(file, 'en');
  assert.equal(entries.find((e) => e.pattern === 'landscape').severity, 'low');
  assert.equal(entries.find((e) => e.pattern === 'robust').severity, 'low');
  assert.equal(entries.find((e) => e.pattern === 'tapestry').severity, 'high');
});

test('commentary after a dash is dropped, the dash inside quotes is kept', () => {
  const file = fixture(
    '# t\n\n## Заборонені фрази\n\n' +
      '- «Варто зазначити, що...» — НЕ плутати з «варто відповісти до кінця листопада»\n' +
      '- «Це не просто X — це Y»\n',
  );
  const { entries } = parseBanned(file, 'uk');
  assert.equal(patterns(entries).includes('варто відповісти до кінця листопада'), false);
  assert.equal(patterns(entries).includes('Варто зазначити, що'), true);
  assert.equal(patterns(entries).includes('Це не просто X — це Y'), true);
});

test('reference sections that are not lists are skipped', () => {
  const { entries } = parseBanned(new URL('en/banned.md', REFERENCES).pathname, 'en');
  // "Model-Specific First-Word Tells" and "Era-Specific AI Vocabulary" are
  // context for a human reader, not patterns to match
  assert.equal(patterns(entries).includes('ChatGPT tends to start with'), false);
  assert.equal(entries.some((e) => e.kind === 'opener' && e.pattern === 'Moreover,'), true);
});

test('every shipped language file parses into all three kinds', () => {
  for (const lang of ['en', 'ru', 'uk']) {
    const { entries } = parseBanned(new URL(`${lang}/banned.md`, REFERENCES).pathname, lang);
    const kinds = new Set(entries.map((e) => e.kind));
    assert.equal(entries.length > 100, true, `${lang}: expected a substantial list, got ${entries.length}`);
    for (const kind of ['vocabulary', 'phrase', 'opener']) {
      assert.equal(kinds.has(kind), true, `${lang}: no ${kind} entries parsed`);
    }
    assert.equal(entries.every((e) => e.pattern.length >= 3), true);
  }
});

test('a crafted entry cannot make the regex crawl', () => {
  // slots are lazy quantifiers; a long chain of them would backtrack badly, so
  // buildMatcher caps how many a single entry gets
  const file = fixture('# t\n\n## Banned Phrases\n\n- "X X X X X X X X end"\n');
  const { entries } = parseBanned(file, 'en');
  const matcher = buildMatcher(entries[0].pattern, { lang: 'en', morph: false });

  const started = Date.now();
  matcher.test('word '.repeat(400) + 'and that is all');
  assert.equal(Date.now() - started < 500, true, 'matching took too long');
});
