/**
 * Punctuation budgets.
 *
 * Punctuation frequency is a review hint, not an authorship test. Russian and
 * Ukrainian also require grammatical тире, so only rhetorical inserted dashes
 * count against the heuristic budget there.
 */

import { splitSentences, wordCount } from '../lib/tokenize.js';

const EM_DASH_PER_WORDS = 500;
const EXCLAMATION_PER_WORDS = 1000;
const MAX_ELLIPSES = 1;

const NOT_JUST = {
  en: /[\p{L}][^.!?\n]{0,40}\s+[—–]\s+it['’]s not just(?![\p{L}])[^.!?\n]{0,60}/giu,
  ru: /[^.!?\n]{2,40}\s+[—–]\s+это не просто(?![\p{L}])[^.!?\n]{0,60}/giu,
  uk: /[^.!?\n]{2,40}\s+[—–]\s+це не просто(?![\p{L}])[^.!?\n]{0,60}/giu,
};

// A spaced dash. Number ranges («5—7») have no spaces and never match.
const SPACED_DASH = /\s[—–]\s/gu;

// Words that follow a zero-copula dash: «X — это Y», «X — значить Y».
// \b is ASCII-only, so Cyrillic words need an explicit "no letter follows".
const COPULA_AFTER = /^\s*(это|це|значит|значить|означает|означає|ось)(?![\p{L}])/iu;

/**
 * Grammatical zero-copula dash in RU/UK: «Киев — столица». Approximated two
 * ways — the dash sits near the head of its clause, where the copula would be,
 * or it is followed by an explicit copula word. Everything else is treated as a
 * rhetorical pause, which is the only kind the skill budgets.
 */
function isGrammaticalDash(sentence, offsetInSentence) {
  if (COPULA_AFTER.test(sentence.slice(offsetInSentence + 1))) return true;
  const before = sentence.slice(0, offsetInSentence);
  const clause = before.split(/[,;:]/).pop() ?? before;
  return wordCount(before) <= 4 || wordCount(clause) <= 3;
}

export function punctuation(text, { lang }) {
  const findings = [];
  const total = wordCount(text);
  const sentences = splitSentences(text);

  // 1. em dashes
  if (lang === 'en') {
    const budget = Math.max(1, Math.floor(total / EM_DASH_PER_WORDS));
    const hits = [...text.matchAll(/[—–]/gu)].filter((m) => {
      const before = text[m.index - 1] ?? '';
      const after = text[m.index + 1] ?? '';
      return !(m[0] === '–' && /\d/.test(before) && /\d/.test(after));
    });
    hits.slice(budget).forEach((m) => {
      findings.push({
        rule: 'em-dash',
        severity: 'low',
        start: m.index,
        end: m.index + m[0].length,
        message: `dash frequency over review threshold (${hits.length} in ${total} words, threshold ${budget})`,
      });
    });
  } else {
    const rhetorical = [];
    for (const sentence of sentences) {
      SPACED_DASH.lastIndex = 0;
      let m;
      while ((m = SPACED_DASH.exec(sentence.text)) !== null) {
        const dashAt = m.index + 1;
        if (isGrammaticalDash(sentence.text, dashAt)) continue;
        rhetorical.push({ start: sentence.start + dashAt, end: sentence.start + dashAt + 1 });
      }
    }
    const budget = Math.max(1, Math.floor(total / EM_DASH_PER_WORDS));
    rhetorical.slice(budget).forEach((hit) => {
      findings.push({
        rule: 'rhetorical-dash',
        severity: 'low',
        start: hit.start,
        end: hit.end,
        message: `rhetorical dash frequency over review threshold (${rhetorical.length} in ${total} words, threshold ${budget}); grammatical тире is excluded`,
      });
    });
  }

  // 2. «X — это не просто Y»
  const notJust = NOT_JUST[lang];
  if (notJust) {
    notJust.lastIndex = 0;
    let m;
    while ((m = notJust.exec(text)) !== null) {
      findings.push({
        rule: 'not-just-construction',
        severity: 'high',
        start: m.index,
        end: m.index + m[0].length,
        message: 'the "not just X — it\'s Y" construction, banned in every language module',
      });
    }
  }

  // 3. exclamation marks
  const bangs = [...text.matchAll(/!/g)];
  const bangBudget = Math.max(1, Math.floor(total / EXCLAMATION_PER_WORDS));
  bangs.slice(bangBudget).forEach((m) => {
    findings.push({
      rule: 'exclamation',
      severity: 'low',
      start: m.index,
      end: m.index + 1,
      message: `exclamation-mark frequency over review threshold (${bangs.length} in ${total} words, threshold ${bangBudget})`,
    });
  });

  // 4. ellipses
  const dots = [...text.matchAll(/\.{3}|…/gu)];
  dots.slice(MAX_ELLIPSES).forEach((m) => {
    findings.push({
      rule: 'ellipsis',
      severity: 'low',
      start: m.index,
      end: m.index + m[0].length,
      message: 'more than one ellipsis — use it only for genuinely trailing off, never as a transition',
    });
  });

  return findings;
}
