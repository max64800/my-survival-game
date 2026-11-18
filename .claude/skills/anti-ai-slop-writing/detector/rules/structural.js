/**
 * Structure, not vocabulary. These are the tells that survive a clean word
 * list: even sentence lengths, groups of three, chains of short declaratives.
 *
 * These rules surface repeated shapes for review. None of them proves
 * authorship, and a single hit may be intentional in its genre.
 */

import { splitSentences, splitBlocks, wordCount } from '../lib/tokenize.js';

const MIN_WORDS_FOR_RHYTHM = 60;
const SAME_LENGTH_RUN = 3;
const SAME_LENGTH_TOLERANCE = 2;
const PARATAXIS_RUN = 4;
const PARATAXIS_MAX_WORDS = 8;

const RULE_OF_THREE = {
  en: /\b([\p{L}\p{N}'’-]+(?:\s+[\p{L}\p{N}'’-]+){0,2}),\s+([\p{L}\p{N}'’-]+(?:\s+[\p{L}\p{N}'’-]+){0,2}),?\s+and\s+([\p{L}\p{N}'’-]+(?:\s+[\p{L}\p{N}'’-]+){0,2})\b/giu,
  ru: /([\p{L}\p{N}'’-]+(?:\s+[\p{L}\p{N}'’-]+){0,2}),\s+([\p{L}\p{N}'’-]+(?:\s+[\p{L}\p{N}'’-]+){0,2})\s+и\s+([\p{L}\p{N}'’-]+(?:\s+[\p{L}\p{N}'’-]+){0,2})/giu,
  uk: /([\p{L}\p{N}'’-]+(?:\s+[\p{L}\p{N}'’-]+){0,2}),\s+([\p{L}\p{N}'’-]+(?:\s+[\p{L}\p{N}'’-]+){0,2})\s+(?:і|та|й)\s+([\p{L}\p{N}'’-]+(?:\s+[\p{L}\p{N}'’-]+){0,2})/giu,
};

// A clause starting with one of these is a subordinate clause, not a list item:
// «графіка відключень, хоч він і бреше» only looks like an enumeration.
const CLAUSE_STARTERS = {
  en: /^(that|which|who|because|although|though|if|when|while|but|so|since|unless)$/i,
  ru: /^(что|чтобы|который|которая|которые|которых|потому|хотя|если|когда|пока|но|а|зато|поскольку|хоть)$/i,
  uk: /^(що|щоб|який|яка|які|яких|бо|хоч|хоча|якщо|коли|поки|але|а|зате|оскільки)$/i,
};

// The lookahead stands in for \b, which only knows about ASCII word characters.
const ROLE_OPENER = {
  en: /^(As\s+(?:an?|the)\s+[^,.]{3,40},\s+I(?![\p{L}]))/imu,
  ru: /^(Как\s+[^,.]{3,40},\s*я(?![\p{L}]))/imu,
  uk: /^(Як\s+[^,.]{3,40},\s*я(?![\p{L}]))/imu,
};

// Verbal-noun pileups: «осуществляется внедрение проведения» / «здійснення впровадження»
const VERBAL_NOUN_CHAIN = {
  ru: /[\p{L}]{3,}(?:ание|ания|анию|анием|ании|ение|ения|ению|ением|ении)\s+[\p{L}]{3,}(?:ание|ания|анию|анием|ании|ение|ения|ению|ением|ении)/giu,
  uk: /[\p{L}]{3,}(?:ання|анню|анням|анні|ення|енню|енням|енні)\s+[\p{L}]{3,}(?:ання|анню|анням|анні|ення|енню|енням|енні)/giu,
  en: null,
};

function standardDeviation(values) {
  if (values.length < 2) return 0;
  const mean = values.reduce((a, b) => a + b, 0) / values.length;
  const variance = values.reduce((a, b) => a + (b - mean) ** 2, 0) / values.length;
  return Math.sqrt(variance);
}

export function structural(text, { lang }) {
  const findings = [];
  const sentences = splitSentences(text).map((s) => ({ ...s, length: wordCount(s.text) }));
  const total = sentences.reduce((sum, s) => sum + s.length, 0);

  // 1. three or more consecutive sentences of the same length
  let run = [sentences[0]].filter(Boolean);
  for (let i = 1; i < sentences.length; i++) {
    // compared against the first of the run, so 5-7-9-11 does not count as flat
    const near = Math.abs(sentences[i].length - run[0].length) <= SAME_LENGTH_TOLERANCE;
    if (near && sentences[i].length >= 5) {
      run.push(sentences[i]);
    } else {
      flushRun(run, findings);
      run = [sentences[i]];
    }
  }
  flushRun(run, findings);

  // 2. parataxis: a string of short declaratives
  let short = [];
  for (const sentence of sentences) {
    if (sentence.length > 0 && sentence.length <= PARATAXIS_MAX_WORDS) {
      short.push(sentence);
    } else {
      flushShort(short, findings);
      short = [];
    }
  }
  flushShort(short, findings);

  // 3. overall burstiness, reported once per file
  if (total >= MIN_WORDS_FOR_RHYTHM && sentences.length >= 6) {
    const lengths = sentences.map((s) => s.length);
    const sd = standardDeviation(lengths);
    const mean = total / sentences.length;
    if (mean > 0 && sd / mean < 0.4) {
      findings.push({
        rule: 'flat-rhythm',
        severity: 'low',
        start: sentences[0].start,
        end: sentences[0].end,
        message: `sentence lengths barely vary (mean ${mean.toFixed(1)} words, sd ${sd.toFixed(1)}) — review whether the rhythm is mechanically flat`,
      });
    }
  }

  // 4. groups of three, checked inside one sentence — a list never spans a period
  const three = RULE_OF_THREE[lang];
  if (three) {
    for (const sentence of sentences) {
      three.lastIndex = 0;
      let m;
      while ((m = three.exec(sentence.text)) !== null) {
        const items = [m[1], m[2], m[3]];
        const subordinate = items.some((item) => CLAUSE_STARTERS[lang]?.test(item.split(/\s+/)[0] ?? ''));
        if (subordinate) continue;
        findings.push({
          rule: 'rule-of-three',
          severity: 'low',
          start: sentence.start + m.index,
          end: sentence.start + m.index + m[0].length,
          message: 'group of three — keep it when the content genuinely has three items; review repeated triads',
        });
      }
    }
  }

  // 5. "As a [role], I..." openers, checked per block so mid-text ones count too
  const role = ROLE_OPENER[lang];
  if (role) {
    for (const block of splitBlocks(text)) {
      const m = block.text.match(role);
      if (m && m.index !== undefined) {
        findings.push({
          rule: 'role-opener',
          severity: 'high',
          start: block.start + m.index,
          end: block.start + m.index + m[0].length,
          message: 'credential opener — real people state the thing without the badge',
        });
      }
    }
  }

  // 6. verbal-noun chains (Russian and Ukrainian bureaucratese)
  const chain = VERBAL_NOUN_CHAIN[lang];
  if (chain) {
    chain.lastIndex = 0;
    let m;
    while ((m = chain.exec(text)) !== null) {
      findings.push({
        rule: 'verbal-noun-chain',
        severity: 'medium',
        start: m.index,
        end: m.index + m[0].length,
        message: 'chain of verbal nouns — say who did what',
      });
    }
  }

  return findings;

  function flushRun(group, out) {
    if (group.length < SAME_LENGTH_RUN) return;
    out.push({
      rule: 'uniform-sentence-length',
      severity: 'low',
      start: group[0].start,
      end: group[group.length - 1].end,
      message: `${group.length} sentences in a row of ~${group[0].length} words — review whether the rhythm is intentionally even`,
    });
  }

  function flushShort(group, out) {
    if (group.length < PARATAXIS_RUN) return;
    out.push({
      rule: 'parataxis',
      severity: 'low',
      start: group[0].start,
      end: group[group.length - 1].end,
      message: `${group.length} short sentences in a row — review whether the staccato rhythm serves the passage`,
    });
  }
}
