/**
 * Sentence and word splitting for Latin and Cyrillic text, plus offset → line
 * mapping. Deliberately simple: the rules that consume it measure rhythm, and
 * rhythm survives an imperfect boundary here and there.
 */

const ABBREVIATIONS = new Set([
  // English
  'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', 'jr', 'st', 'vs', 'etc', 'e.g', 'i.e',
  'inc', 'ltd', 'co', 'fig', 'no', 'approx',
  // Russian / Ukrainian
  'т', 'д', 'п', 'г', 'гг', 'в', 'вв', 'см', 'ср', 'напр', 'рис', 'табл', 'стр',
  'обл', 'руб', 'грн', 'тыс', 'млн', 'млрд', 'проф', 'акад', 'им', 'ул', 'просп',
  'тис', 'грв',
]);

const SENTENCE_END = /[.!?…]+["'»”)\]]*/g;

/**
 * @param {string} text
 * @returns {{text: string, start: number, end: number}[]}
 */
export function splitSentences(text) {
  const sentences = [];
  let cursor = 0;
  SENTENCE_END.lastIndex = 0;
  let m;

  while ((m = SENTENCE_END.exec(text)) !== null) {
    const end = m.index + m[0].length;
    const next = text.slice(end, end + 2);

    // a boundary needs whitespace or end of text after it
    if (next.length > 0 && !/^[\s]/.test(next)) continue;

    const before = text.slice(Math.max(0, m.index - 12), m.index);
    const lastWord = (before.match(/([\p{L}.]+)$/u)?.[1] ?? '').toLowerCase();
    if (m[0] === '.' && (ABBREVIATIONS.has(lastWord) || /^\p{L}$/u.test(lastWord))) continue;

    push(sentences, text, cursor, end);
    cursor = end;
  }
  push(sentences, text, cursor, text.length);

  return sentences;
}

function push(list, text, start, end) {
  const raw = text.slice(start, end);
  const leading = raw.length - raw.trimStart().length;
  const trimmed = raw.trim();
  if (trimmed.length === 0) return;
  list.push({ text: trimmed, start: start + leading, end: start + leading + trimmed.length });
}

/**
 * Paragraph-ish blocks: separated by a blank line. Headings and list items are
 * their own blocks, so a bulleted list is not read as one giant paragraph.
 */
export function splitBlocks(text) {
  const blocks = [];
  let start = 0;
  const re = /\n[ \t]*\n/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    blocks.push({ text: text.slice(start, m.index), start });
    start = m.index + m[0].length;
  }
  blocks.push({ text: text.slice(start), start });
  return blocks.filter((b) => b.text.trim().length > 0);
}

const WORD = /[\p{L}\p{N}]+(?:['’\-][\p{L}\p{N}]+)*/gu;

/** @returns {string[]} */
export function words(text) {
  return text.match(WORD) ?? [];
}

export function wordCount(text) {
  return words(text).length;
}

/**
 * Builds an offset → {line, column} lookup. Both are 1-based, matching what
 * editors and CI annotations expect.
 */
export function positions(text) {
  const starts = [0];
  for (let i = 0; i < text.length; i++) {
    if (text[i] === '\n') starts.push(i + 1);
  }
  return (offset) => {
    let lo = 0;
    let hi = starts.length - 1;
    while (lo < hi) {
      const mid = Math.ceil((lo + hi) / 2);
      if (starts[mid] <= offset) lo = mid;
      else hi = mid - 1;
    }
    return { line: lo + 1, column: offset - starts[lo] + 1 };
  };
}

/**
 * A short quote around an offset, for the report. Collapses whitespace so a
 * finding stays on one line.
 */
const MAX_EXCERPT = 110;

export function excerpt(text, start, end, pad = 30) {
  const from = Math.max(0, start - pad);
  const to = Math.min(text.length, end + pad);
  const head = from > 0 ? '…' : '';
  const tail = to < text.length ? '…' : '';
  const body = text.slice(from, to).replace(/\s+/g, ' ').trim();
  if (body.length <= MAX_EXCERPT) return head + body + tail;
  // long spans (a whole run of sentences) show both ends, not a wall of text
  const side = Math.floor((MAX_EXCERPT - 5) / 2);
  return `${head + body.slice(0, side)} […] ${body.slice(-side)}${tail}`;
}

const CYRILLIC = /[Ѐ-ӿ]/g;
const UKRAINIAN_ONLY = /[іїєґІЇЄҐ]/g;
const RUSSIAN_ONLY = /[ыъэёЫЪЭЁ]/g;

/**
 * Guesses the output language. Ukrainian and Russian share most of the
 * alphabet, so the split leans on the letters only one of them uses.
 */
export function detectLanguage(text) {
  const letters = (text.match(/\p{L}/gu) ?? []).length;
  if (letters === 0) return 'en';
  const cyrillic = (text.match(CYRILLIC) ?? []).length;
  if (cyrillic / letters < 0.25) return 'en';

  const uk = (text.match(UKRAINIAN_ONLY) ?? []).length;
  const ru = (text.match(RUSSIAN_ONLY) ?? []).length;
  return uk > ru ? 'uk' : 'ru';
}
