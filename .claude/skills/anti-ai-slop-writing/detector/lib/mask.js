/**
 * Blanks out regions that must never be linted: code, links, frontmatter,
 * blockquotes. Replaces them with spaces instead of deleting them, so every
 * offset in the masked text still points at the same place in the original.
 *
 * Without this the repository would fail its own self-scan: banned.md is a list
 * of banned words, and patterns.md quotes the bad version of every rewrite.
 */

const REGIONS = [
  // YAML frontmatter, opening the file only
  { name: 'frontmatter', re: /^---\r?\n[\s\S]*?\r?\n---/ },
  // fenced code blocks
  { name: 'fence', re: /(^|\n)(```|~~~)[^\n]*\n[\s\S]*?(\n\2[^\n]*|$)/g },
  // indented code blocks (four spaces, not inside a list — approximated)
  { name: 'html-comment', re: /<!--[\s\S]*?-->/g },
  // inline code
  { name: 'code', re: /`[^`\n]+`/g },
  // markdown link and image targets: keep the visible text, blank the URL
  { name: 'link-target', re: /\]\([^)\s]*(\s+"[^"]*")?\)/g },
  // the "!" of an image is syntax, not an exclamation mark
  { name: 'image-bang', re: /!(?=\[)/g },
  // bare URLs and autolinks
  { name: 'url', re: /<?\bhttps?:\/\/[^\s<>)]+>?/g },
  // reference definitions
  { name: 'ref-def', re: /^\s*\[[^\]]+\]:\s*\S+.*$/gm },
  // blockquotes: quoted material belongs to whoever is quoted
  { name: 'quote', re: /^[ \t]*>[^\n]*$/gm },
];

/**
 * @param {string} text
 * @returns {string} same length as `text`, with masked regions turned to spaces
 */
export function mask(text) {
  // split('') keeps UTF-16 units, which is what regex indices count in
  const chars = text.split('');
  const blank = (start, end) => {
    for (let i = start; i < end && i < chars.length; i++) {
      if (chars[i] !== '\n' && chars[i] !== '\r') chars[i] = ' ';
    }
  };

  for (const { re } of REGIONS) {
    if (re.global) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(text)) !== null) {
        blank(m.index, m.index + m[0].length);
        if (m[0].length === 0) re.lastIndex++;
      }
    } else {
      const m = text.match(re);
      if (m && m.index === 0) blank(0, m[0].length);
    }
  }

  return chars.join('');
}

/**
 * Strips markdown decoration (headings, list markers, emphasis, tables) without
 * changing the length of the string. Used by the rules that measure prose, so a
 * heading does not read as a one-word sentence and a table of terse cells does
 * not read as a run of same-length sentences.
 */
export function stripMarkup(text) {
  return text
    .replace(/^([ \t]*)(#{1,6}\s+)/gm, (_, ws, hashes) => ws + ' '.repeat(hashes.length))
    .replace(/^([ \t]*)([-*+]\s+|\d+[.)]\s+)/gm, (_, ws, marker) => ws + ' '.repeat(marker.length))
    .replace(/^[ \t]*\|.*$/gm, (row) => ' '.repeat(row.length))
    .replace(/(\*\*|__|\*|_)/g, (m) => ' '.repeat(m.length));
}
