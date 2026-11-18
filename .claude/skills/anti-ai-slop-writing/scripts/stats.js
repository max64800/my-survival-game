#!/usr/bin/env node
/**
 * Counts what the skill actually ships, so the numbers in README and docs come
 * from the files rather than from memory.
 *
 *   node scripts/stats.js
 *   node scripts/stats.js --json
 */

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join } from 'node:path';

import { parseBanned } from '../detector/lib/parse-banned.js';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const LANGUAGES = ['en', 'ru', 'uk'];

const wordCount = (text) => text.trim().split(/\s+/u).filter(Boolean).length;
const skillWords = wordCount(readFileSync(join(ROOT, 'SKILL.md'), 'utf8'));
const deepAuditWords = wordCount(readFileSync(join(ROOT, 'references', 'core', 'craft.md'), 'utf8'));
const stats = {
  languages: {},
  prompt: { skillWords, deepAuditWords },
  totals: { vocabulary: 0, phrase: 0, opener: 0, entries: 0 },
};

for (const lang of LANGUAGES) {
  const { entries } = parseBanned(join(ROOT, 'references', lang, 'banned.md'), lang);
  const count = (kind) => entries.filter((e) => e.kind === kind).length;
  const patterns = readFileSync(join(ROOT, 'references', lang, 'patterns.md'), 'utf8');
  const rewrites = (patterns.match(/^###\s+\d+\./gm) ?? []).length;

  stats.languages[lang] = {
    vocabulary: count('vocabulary'),
    phrase: count('phrase'),
    opener: count('opener'),
    entries: entries.length,
    rewritePatterns: rewrites,
    defaultPromptWords: skillWords + wordCount(readFileSync(join(ROOT, 'references', lang, 'rules.md'), 'utf8')),
  };
  for (const kind of ['vocabulary', 'phrase', 'opener']) stats.totals[kind] += count(kind);
  stats.totals.entries += entries.length;
}

if (process.argv.includes('--json')) {
  console.log(JSON.stringify(stats, null, 2));
} else {
  console.log('lang  vocabulary  phrases  openers  total  rewrites  default prompt words');
  for (const [lang, row] of Object.entries(stats.languages)) {
    console.log(
      `${lang.padEnd(6)}${String(row.vocabulary).padEnd(12)}${String(row.phrase).padEnd(9)}${String(row.opener).padEnd(9)}${String(row.entries).padEnd(7)}${String(row.rewritePatterns).padEnd(10)}${row.defaultPromptWords}`,
    );
  }
  const t = stats.totals;
  console.log(`\nall   ${t.vocabulary} vocabulary, ${t.phrase} phrases, ${t.opener} openers — ${t.entries} matchable entries`);
  console.log(`deep audit add-on: ${deepAuditWords} words`);
}
