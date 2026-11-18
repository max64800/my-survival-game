/**
 * Vocabulary, phrases and openers, all driven by references/<lang>/banned.md.
 *
 * Openers only count at the start of a sentence: «Действительно,» opening a
 * paragraph is a tell, the same word mid-sentence is ordinary Russian.
 */

import { buildMatcher } from '../lib/morphology.js';
import { splitSentences } from '../lib/tokenize.js';

/**
 * Forms that a stem legitimately produces but that mean something else.
 * «данный» is канцелярит; «данные» is data, and every technical text has it.
 * Stemming cannot separate the two, so the exceptions are listed by hand.
 */
const HOMOGRAPHS = new Set([
  'данные', 'данных', 'данными', 'данным', 'данной', // data, not «этот»
  'дані', 'даних', 'даними', 'даним',
]);

const compiled = new WeakMap();

/** Compiling ~150 regexes per file adds up; keyed on the parsed banned list. */
function prepare(banned, lang) {
  const hit = compiled.get(banned);
  if (hit) return hit;

  // English multi-word phrases are quoted literally in banned.md, so they match
  // as written. Single words still need their -s/-ed/-ing forms.
  const build = (list) =>
    list.map((entry) => ({
      entry,
      matcher: buildMatcher(entry.pattern, { lang, morph: lang !== 'en' || !/\s/.test(entry.pattern) }),
    }));

  const prepared = {
    inline: build(banned.entries.filter((e) => e.kind !== 'opener')),
    openers: build(banned.entries.filter((e) => e.kind === 'opener')),
  };
  compiled.set(banned, prepared);
  return prepared;
}

function describe(entry) {
  const label =
    entry.kind === 'vocabulary' ? 'banned word' : entry.kind === 'opener' ? 'banned opener' : 'banned phrase';
  const parts = [`${label}: “${entry.pattern}”`];
  if (entry.fix) parts.push(`use ${entry.fix} instead`);
  else if (entry.note && entry.severity !== 'high') parts.push(`banned ${entry.note}`);
  return parts.join(' — ');
}

/**
 * @param {string} text     masked text
 * @param {object} context  { lang, banned }
 * @returns {object[]} raw findings, positions resolved by the caller
 */
export function lexical(text, { lang, banned }) {
  const findings = [];
  const { inline, openers } = prepare(banned, lang);

  for (const { entry, matcher } of inline) {
    matcher.lastIndex = 0;
    let m;
    while ((m = matcher.exec(text)) !== null) {
      if (HOMOGRAPHS.has(m[0].toLowerCase())) {
        if (m[0].length === 0) matcher.lastIndex++;
        continue;
      }
      findings.push({
        rule: entry.kind === 'vocabulary' ? 'banned-word' : 'banned-phrase',
        severity: entry.severity,
        start: m.index,
        end: m.index + m[0].length,
        message: describe(entry),
        fix: entry.fix,
      });
      if (m[0].length === 0) matcher.lastIndex++;
    }
  }

  if (openers.length > 0) {
    for (const sentence of splitSentences(text)) {
      for (const { entry, matcher } of openers) {
        matcher.lastIndex = 0;
        const m = matcher.exec(sentence.text);
        if (m && m.index === 0) {
          findings.push({
            rule: 'banned-opener',
            severity: entry.severity,
            start: sentence.start,
            end: sentence.start + m[0].length,
            message: describe(entry),
            fix: entry.fix,
          });
        }
      }
    }
  }

  return dedupe(findings);
}

/**
 * Overlapping hits are the same defect seen twice — «В современном мире» is
 * both a banned phrase and the banned word «мир». Keep the longer, harsher one.
 */
function dedupe(findings) {
  const rank = { high: 3, medium: 2, low: 1 };
  const sorted = [...findings].sort(
    (a, b) => a.start - b.start || b.end - b.start - (a.end - a.start) || rank[b.severity] - rank[a.severity],
  );
  const kept = [];
  for (const finding of sorted) {
    const clash = kept.find((k) => finding.start < k.end && k.start < finding.end);
    if (!clash) kept.push(finding);
  }
  return kept;
}
