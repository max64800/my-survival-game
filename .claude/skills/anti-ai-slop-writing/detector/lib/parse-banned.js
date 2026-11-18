/**
 * Reads `references/<lang>/banned.md` and turns it into detector entries.
 *
 * The markdown files are the single source of truth: the model reads them, and
 * so does the linter. Add a word to banned.md and the detector picks it up on
 * the next run — there is no second list to keep in sync.
 *
 * What the parser understands:
 *
 *   delve / delves / delving        → three separate patterns
 *   landscape (figurative)          → condition it cannot verify, severity drops
 *   данный (→ этот)                 → the arrow becomes the suggested fix
 *   эпоха («в эпоху»)               → the quoted example replaces the bare word
 *   - "It's worth noting that..."   → phrase, trailing ellipsis dropped
 */

import { readFileSync } from 'node:fs';

const SECTION_KINDS = [
  { kind: 'vocabulary', re: /vocabulary|лексик|канцеляр/i },
  { kind: 'phrase', re: /phrase|фраз/i },
  { kind: 'opener', re: /opener|зачин/i },
];

// Reference sections written for a human reader, not lists to match against.
// "Model-Specific First-Word Tells" is about the first word of a chat reply;
// "Era-Specific AI Vocabulary" is history, and its live entries are in the main
// list already. Both would otherwise be read as vocabulary.
const REFERENCE_SECTIONS = /model-specific|era-specific|first-word|for context|для контекста|для контексту/i;

const CONDITION_HINTS =
  /figurative|as filler|non-literal|outside|casual|describing|e\.?g\.?|say\b|переносн|как филлер|як філер|вне |поза |в значении|у значенні|как финал|як фінал|зачин|paragraph starter|range opener|механическая|механічна|автоподпись|автопідпис|ланцюжк|в кожному|риторическ|риторичн/i;

/** Splits on a separator that sits outside brackets and quotes. */
function splitTopLevel(input, separator) {
  const out = [];
  let depth = 0;
  let quote = 0;
  let current = '';
  for (const ch of input) {
    if (ch === '(') depth++;
    else if (ch === ')') depth = Math.max(0, depth - 1);
    else if (ch === '«') quote++;
    else if (ch === '»') quote = Math.max(0, quote - 1);

    if (ch === separator && depth === 0 && quote === 0) {
      out.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  out.push(current);
  return out.map((s) => s.trim()).filter((s) => s.length > 0);
}

const QUOTED = /«([^»]+)»|"([^"]+)"|“([^”]+)”/g;

function quotedParts(text) {
  QUOTED.lastIndex = 0;
  const parts = [];
  let m;
  while ((m = QUOTED.exec(text)) !== null) parts.push((m[1] ?? m[2] ?? m[3]).trim());
  return parts;
}

/** Trailing "..." in a list entry means "the phrase continues", not literal dots. */
function trimEllipsis(text) {
  return text.replace(/\s*(\.{3}|…)\s*$/, '').trim();
}

function stripQuotes(text) {
  return text.replace(/^[«"“'\s]+/, '').replace(/[»"”'\s]+$/, '').trim();
}

/** True when the quoted example is built from the term itself, not a synonym. */
function containsTerm(example, terms) {
  const haystack = example.toLowerCase();
  return terms.some((term) => {
    const word = term.toLowerCase().split(/\s+/).pop() ?? '';
    if (word.length < 4) return haystack.includes(word);
    return haystack.includes(word.slice(0, Math.max(4, word.length - 2)));
  });
}

/**
 * One comma-separated vocabulary item, or one quoted phrase.
 * @returns {{patterns: string[], severity: string, fix?: string, note?: string}}
 */
function parseEntry(raw) {
  const text = raw.trim();
  const bracket = text.match(/\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)\s*$/);
  const head = bracket ? text.slice(0, bracket.index).trim() : text;
  const inside = bracket ? bracket[1].trim() : '';

  let severity = 'high';
  let fix;
  let note;
  let patterns = splitTopLevel(head, '/').map((p) => trimEllipsis(stripQuotes(p)));

  if (inside) {
    note = inside;
    const arrow = inside.match(/(?:→|->)\s*(.+)$/);
    const said = inside.match(/say\s+"([^"]+)"/i);
    const examples = quotedParts(inside);

    if (arrow) {
      fix = arrow[1].trim();
      severity = 'medium';
    } else if (said) {
      fix = said[1].trim();
      severity = 'medium';
    } else if (examples.length > 0 && examples.some((ex) => containsTerm(ex, patterns))) {
      // «эпоха («в эпоху»)» — the quoted example is a narrower form of the same
      // word, so it makes the better pattern. But «производить (в значении
      // «делать»)» quotes a gloss, not the term: banning «делать» would be wrong.
      patterns = examples.filter((ex) => containsTerm(ex, patterns)).map(trimEllipsis);
      severity = 'medium';
    } else if (CONDITION_HINTS.test(inside) || examples.length > 0) {
      // a condition the detector cannot check: usage is only banned in one sense
      severity = 'low';
    } else {
      severity = 'medium';
    }
  }

  patterns = patterns.filter((p) => p.length >= 3);
  return { patterns, severity, fix, note };
}

function parseVocabularyLine(line) {
  let category;
  let body = line;
  const colon = line.indexOf(':');
  if (colon > 0 && colon < 40 && !line.slice(0, colon).includes(',') && !line.slice(0, colon).includes('(')) {
    category = line.slice(0, colon).trim();
    body = line.slice(colon + 1);
  }
  return splitTopLevel(body, ',').map((item) => ({ ...parseEntry(item), category, source: item }));
}

/**
 * Index of the first " — " that sits outside quotes, or -1.
 * «Это не просто X — это Y» keeps its dash: it is part of the pattern.
 * «Варто зазначити...» — НЕ плутати з... loses everything after the dash.
 */
function commentaryDash(text) {
  let quote = 0;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === '«' || ch === '“') quote++;
    else if (ch === '»' || ch === '”') quote = Math.max(0, quote - 1);
    else if (ch === '"') quote = quote === 0 ? 1 : 0;
    else if (quote === 0 && (ch === '—' || ch === '–') && /\s/.test(text[i - 1] ?? '') && /\s/.test(text[i + 1] ?? '')) {
      return i - 1;
    }
  }
  return -1;
}

function parsePhraseLine(line) {
  const body = line.replace(/^[-*]\s+/, '');
  const cut = commentaryDash(body);
  const head = cut > 0 ? body.slice(0, cut) : body;
  const tail = cut > 0 ? body.slice(cut) : '';

  const quoted = quotedParts(head);
  const raw = quoted.length > 0 ? quoted : [head.replace(/\s*\([^)]*\)\s*$/, '')];

  const commented = tail.length > 0;
  return raw.flatMap((piece) => {
    const entry = parseEntry(piece);
    // a bullet carrying prose commentary states a condition we cannot verify
    if (commented && entry.severity === 'high') entry.severity = 'medium';
    return [{ ...entry, source: piece }];
  });
}

function parseOpenerBlock(text) {
  const quoted = quotedParts(text);
  if (quoted.length > 0) {
    return quoted.flatMap((piece) => {
      const entry = parseEntry(piece);
      return [{ ...entry, source: piece }];
    });
  }
  return [];
}

/**
 * @param {string} file  path to references/<lang>/banned.md
 * @param {string} lang
 * @returns {{lang: string, entries: object[]}}
 */
export function parseBanned(file, lang) {
  const text = readFileSync(file, 'utf8');
  const lines = text.split(/\r?\n/);

  const entries = [];
  let kind = null;

  for (const line of lines) {
    const heading = line.match(/^##\s+(.*)$/);
    if (heading) {
      const title = heading[1];
      kind = REFERENCE_SECTIONS.test(title) ? null : (SECTION_KINDS.find((s) => s.re.test(title))?.kind ?? null);
      continue;
    }
    if (line.startsWith('# ')) continue;
    if (!kind) continue;

    const trimmed = line.trim();
    if (trimmed.length === 0) continue;
    // the intro paragraph under the top heading, not a list
    if (kind === 'vocabulary' && /^Standalone module|^Самостоятельный модуль|^Самостійний модуль/.test(trimmed)) continue;

    if (kind === 'phrase' || (kind === 'opener' && /^[-*]\s/.test(trimmed))) {
      if (!/^[-*]\s/.test(trimmed)) continue;
      entries.push(...parsePhraseLine(trimmed).map((e) => ({ ...e, kind })));
    } else if (kind === 'opener') {
      entries.push(...parseOpenerBlock(trimmed).map((e) => ({ ...e, kind: 'opener' })));
    } else if (kind === 'vocabulary') {
      entries.push(...parseVocabularyLine(trimmed).map((e) => ({ ...e, kind: 'vocabulary' })));
    }
  }

  const seen = new Set();
  const unique = [];
  for (const entry of entries) {
    for (const pattern of entry.patterns) {
      const key = `${entry.kind}:${pattern.toLowerCase()}`;
      if (seen.has(key)) continue;
      seen.add(key);
      unique.push({ ...entry, pattern, lang });
    }
  }

  return { lang, entries: unique };
}
