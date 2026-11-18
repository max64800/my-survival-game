/**
 * Turns a banned-list entry into a regular expression.
 *
 * Russian and Ukrainian inflect, so «данный» has to catch «данного» and
 * «данным» without the list carrying every form. The approach is deliberately
 * crude — chop one or two trailing letters, allow a short ending — because a
 * style linter pays more for a false positive than for a missed inflection.
 */

const CYRILLIC_ENDING = "[а-яёіїєґА-ЯЁІЇЄҐ'’ʼ]";
const LATIN_ENDING = '(?:s|es|d|ed|ing)?';

// A word boundary that works for Cyrillic too — \b only knows about ASCII.
const LEFT = '(?<![\\p{L}\\p{N}_])';
const RIGHT = '(?![\\p{L}\\p{N}_])';

const PLACEHOLDER = '[^\\n]{1,30}?';
const MAX_SLOTS = 2;

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/** Apostrophes travel in three shapes; accept any of them. */
function anyApostrophe(source) {
  return source.replace(/['’ʼ]/g, "['’ʼ]");
}

// Infinitives conjugate further than nouns decline: «здійснювати» → «здійснює»
// keeps only «здійсн». Ordered longest-first so «ювати» wins over «ати».
const INFINITIVE_ENDINGS = [
  'ювати', 'увати', 'овать', 'евать', 'ивать', 'ывать', 'ляться', 'ться',
  'ити', 'ать', 'ять', 'еть', 'ить', 'ти',
];

// Adjectives lose the whole ending, not one letter: «даний» declines to
// «даного», which shares only «дан». Cutting a single letter would miss it.
const ADJECTIVE_ENDINGS = ['ий', 'ій', 'ый', 'ой', 'ая', 'яя', 'ое', 'ее', 'ые', 'ие', 'ій'];

/** Cyrillic stem + allowed ending, sized by how long the word is. */
function inflect(word) {
  if (word.length <= 3) return anyApostrophe(escapeRegExp(word));

  const verb = INFINITIVE_ENDINGS.find((end) => word.endsWith(end) && word.length - end.length >= 4);
  if (verb) {
    // «производ» + ending catches «производит» and «производили»; the guard
    // keeps it off «производство», which is a noun and not on anyone's list
    return anyApostrophe(escapeRegExp(word.slice(0, -verb.length))) + `(?!ств)${CYRILLIC_ENDING}{0,4}`;
  }

  if (word.length === 4) return anyApostrophe(escapeRegExp(word)) + `${CYRILLIC_ENDING}{0,3}`;

  const adjective = ADJECTIVE_ENDINGS.find((end) => word.endsWith(end) && word.length - end.length >= 3);
  if (adjective) {
    return anyApostrophe(escapeRegExp(word.slice(0, -adjective.length))) + `${CYRILLIC_ENDING}{1,4}`;
  }

  const cut = word.length >= 6 ? 2 : 1;
  return anyApostrophe(escapeRegExp(word.slice(0, -cut))) + `${CYRILLIC_ENDING}{0,4}`;
}

function isCyrillic(word) {
  return /[Ѐ-ӿ]/.test(word);
}

/**
 * @param {string} phrase   entry text, may contain X / Y / [noun] placeholders
 * @param {object} options
 * @param {string} options.lang        'en' | 'ru' | 'uk'
 * @param {boolean} [options.morph]    allow inflected forms (default true)
 * @param {boolean} [options.anchored] only match at the start of a sentence
 * @returns {RegExp}
 */
export function buildMatcher(phrase, { lang, morph = true, anchored = false } = {}) {
  const tokens = phrase.trim().split(/(\s+)/).filter((t) => t.length > 0);
  const parts = [];
  let slots = 0;

  for (const token of tokens) {
    if (/^\s+$/.test(token)) {
      // punctuation inside a listed phrase is optional: «Стоит отметить, что»
      // has to match whether or not the writer kept the comma
      parts.push('[,;:]?\\s+');
      continue;
    }
    // [adjective], [X] — a slot the writer fills in; bare X / Y do the same job.
    // Slots are capped: each one is a lazy quantifier, and a crafted entry with
    // a long chain of them would make the regex crawl. The shipped lists top out
    // at two ("In today's [adjective] [noun]"), so the cap costs nothing real.
    if (/^\[[^\]]+\][.,!?…]*$/.test(token) || /^[XY][.,!?…]*$/.test(token)) {
      if (slots < MAX_SLOTS) {
        slots++;
        parts.push(PLACEHOLDER);
      } else {
        // beyond the cap a slot matches a single word, which cannot backtrack
        // across spaces the way the lazy version can
        parts.push('\\S{1,30}');
      }
      continue;
    }

    const trailing = token.match(/[.,!?…]+$/)?.[0] ?? '';
    const core = trailing ? token.slice(0, -trailing.length) : token;
    if (core.length === 0) {
      parts.push(escapeRegExp(token));
      continue;
    }

    let piece;
    if (isCyrillic(core)) {
      piece = morph ? inflect(core) : escapeRegExp(core);
    } else if (/^[\p{L}]+$/u.test(core)) {
      piece = anyApostrophe(escapeRegExp(core)) + (morph ? LATIN_ENDING : '');
    } else {
      piece = anyApostrophe(escapeRegExp(core)).replace(/-/g, '[-–—]');
    }

    // trailing punctuation in a list entry marks "phrase continues", not literal
    parts.push(piece);
  }

  const body = parts.join('');
  const left = anchored ? '' : LEFT;
  return new RegExp(left + body + RIGHT, 'giu');
}

export { escapeRegExp };
