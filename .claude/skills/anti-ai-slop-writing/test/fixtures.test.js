/**
 * The two-sided check. A style linter that only proves it can find slop is half
 * a linter: the human fixtures are there to fail loudly the day a rule starts
 * over-editing ordinary writing.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

import { detect } from '../detector/index.js';

const LANGS = ['en', 'ru', 'uk'];
const read = (kind, lang) => readFileSync(new URL(`fixtures/${kind}/${lang}.md`, import.meta.url), 'utf8');

for (const lang of LANGS) {
  test(`slop fixture (${lang}) is caught`, () => {
    const { issues, stats, lang: guessed } = detect(read('slop', lang));
    assert.equal(guessed, lang, 'language should be detected without a hint');
    assert.equal(issues.length >= 15, true, `expected 15+ findings, got ${issues.length}`);
    assert.equal(stats.bySeverity.high >= 8, true, `expected 8+ high findings, got ${stats.bySeverity.high}`);
  });

  test(`human fixture (${lang}) is clean`, () => {
    const { issues, lang: guessed } = detect(read('human', lang));
    assert.equal(guessed, lang);
    assert.deepEqual(
      issues.map((i) => `${i.line}:${i.column} ${i.rule} — ${i.excerpt}`),
      [],
      'human writing must not be flagged',
    );
  });
}

test('the gap between slop and human is wide, not marginal', () => {
  for (const lang of LANGS) {
    const slop = detect(read('slop', lang)).stats.per1000;
    const human = detect(read('human', lang)).stats.per1000;
    assert.equal(slop > human + 100, true, `${lang}: slop ${slop}/1000 vs human ${human}/1000`);
  }
});
