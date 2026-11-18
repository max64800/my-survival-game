/**
 * Anti-AI-Slop detector — public API.
 *
 *   import { detect } from 'anti-ai-slop-writing/detector';
 *   const { issues, stats } = detect(text, { lang: 'ru' });
 *
 * The detector is advisory. It reads the same references/<lang>/banned.md the
 * skill reads, so vocabulary and structure stay in sync, but it cannot judge
 * the things SKILL.md cares about most — whether a scene beats its summary,
 * whether the painful number is in a main clause. Those need a reader.
 */

import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';

import { mask, stripMarkup } from './lib/mask.js';
import { detectLanguage, excerpt, positions, wordCount } from './lib/tokenize.js';
import { parseBanned } from './lib/parse-banned.js';
import { lexical } from './rules/lexical.js';
import { structural } from './rules/structural.js';
import { punctuation } from './rules/punctuation.js';
import { formatting } from './rules/formatting.js';

export const LANGUAGES = ['en', 'ru', 'uk'];
export const SEVERITIES = ['high', 'medium', 'low'];

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const bannedCache = new Map();

/** Where the language modules live. Overridable for tests and forks. */
export function referencesDir(root = packageRoot) {
  return join(root, 'references');
}

export function loadBanned(lang, root = packageRoot) {
  const key = `${root}:${lang}`;
  const hit = bannedCache.get(key);
  if (hit) return hit;

  const file = join(referencesDir(root), lang, 'banned.md');
  if (!existsSync(file)) {
    // "If a module file is missing, skip it" — SKILL.md, module map
    const empty = { lang, entries: [] };
    bannedCache.set(key, empty);
    return empty;
  }
  const parsed = parseBanned(file, lang);
  bannedCache.set(key, parsed);
  return parsed;
}

/**
 * @param {string} text
 * @param {object} [options]
 * @param {'en'|'ru'|'uk'|'auto'} [options.lang]
 * @param {string[]} [options.only]      run only these rules
 * @param {string[]} [options.ignore]    skip these rules
 * @param {'high'|'medium'|'low'} [options.severity]  minimum severity reported
 * @param {string} [options.root]        package root, for forks and tests
 * @returns {{lang: string, issues: object[], stats: object}}
 */
export function detect(text, options = {}) {
  const { only, ignore, severity = 'low', root = packageRoot } = options;
  const lang = !options.lang || options.lang === 'auto' ? detectLanguage(text) : options.lang;
  if (!LANGUAGES.includes(lang)) {
    throw new Error(`unsupported language: ${lang} (expected one of ${LANGUAGES.join(', ')})`);
  }

  const masked = mask(text);
  const prose = stripMarkup(masked);
  const banned = loadBanned(lang, root);

  const raw = [
    ...lexical(masked, { lang, banned }),
    ...structural(prose, { lang }),
    ...punctuation(prose, { lang }),
    ...formatting(masked),
  ];

  const at = positions(text);
  const minRank = SEVERITIES.indexOf(severity);

  const issues = raw
    .filter((issue) => (only ? only.includes(issue.rule) : true))
    .filter((issue) => (ignore ? !ignore.includes(issue.rule) : true))
    .filter((issue) => SEVERITIES.indexOf(issue.severity) <= minRank)
    .map((issue) => ({
      ...issue,
      ...at(issue.start),
      excerpt: excerpt(text, issue.start, issue.end),
    }))
    .sort((a, b) => a.start - b.start);

  const byRule = {};
  const bySeverity = { high: 0, medium: 0, low: 0 };
  for (const issue of issues) {
    byRule[issue.rule] = (byRule[issue.rule] ?? 0) + 1;
    bySeverity[issue.severity] += 1;
  }

  const wordTotal = wordCount(masked);
  return {
    lang,
    issues,
    stats: {
      words: wordTotal,
      issues: issues.length,
      per1000: wordTotal > 0 ? Number(((issues.length / wordTotal) * 1000).toFixed(1)) : 0,
      byRule,
      bySeverity,
      bannedEntries: banned.entries.length,
    },
  };
}

export { detectLanguage, mask, parseBanned };
