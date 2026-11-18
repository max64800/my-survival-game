#!/usr/bin/env node
/**
 * Structural validation of the skill itself.
 *
 * The skill is loaded by an agent, not by a compiler, so nothing else would
 * catch a broken reference link or a description that grew past the limit —
 * until the day the skill silently stops loading.
 */

import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join } from 'node:path';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const LANGUAGES = ['en', 'ru', 'uk'];
const MODULES = ['rules.md', 'banned.md', 'patterns.md'];
const DESCRIPTION_LIMIT = 1024;
const DEFAULT_PROMPT_WORD_LIMIT = 850;
const DEEP_AUDIT_WORD_LIMIT = 450;

const problems = [];
const notes = [];

const fail = (message) => problems.push(message);
const note = (message) => notes.push(message);
const wordCount = (text) => text.trim().split(/\s+/u).filter(Boolean).length;

function readFrontmatter(text) {
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return null;
  const body = match[1];

  const name = body.match(/^name:\s*(.+)$/m)?.[1]?.trim();
  const version = body.match(/^\s+version:\s*["']?([^"'\n]+)["']?\s*$/m)?.[1]?.trim();

  // description uses a YAML folded block, so it spans lines until the next key
  const descriptionMatch = body.match(/^description:\s*(?:>-|>|\|)?\s*\n([\s\S]*?)(?=^\S)/m);
  const inline = body.match(/^description:\s*(.+)$/m)?.[1]?.trim();
  const description = descriptionMatch
    ? descriptionMatch[1].split('\n').map((l) => l.trim()).filter(Boolean).join(' ')
    : inline;

  return { name, version, description };
}

// 1. SKILL.md and its frontmatter
const skillPath = join(ROOT, 'SKILL.md');
if (!existsSync(skillPath)) {
  fail('SKILL.md is missing');
} else {
  const skill = readFileSync(skillPath, 'utf8');
  const front = readFrontmatter(skill);

  if (!front) fail('SKILL.md has no YAML frontmatter');
  else {
    if (front.name !== 'anti-ai-slop-writing') fail(`frontmatter name is "${front.name}", expected anti-ai-slop-writing`);
    if (!front.description) fail('frontmatter has no description');
    else {
      const length = front.description.length;
      if (length > DESCRIPTION_LIMIT) fail(`description is ${length} chars, limit is ${DESCRIPTION_LIMIT}`);
      else note(`description ${length}/${DESCRIPTION_LIMIT} chars`);
    }
    if (!front.version) fail('frontmatter has no metadata.version');

    // 2. version agreement across skill, package and changelog
    const pkg = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf8'));
    if (front.version && pkg.version !== front.version) {
      fail(`package.json version ${pkg.version} does not match SKILL.md ${front.version}`);
    }
    const changelog = join(ROOT, 'CHANGELOG.md');
    if (existsSync(changelog)) {
      const top = readFileSync(changelog, 'utf8').match(/^##\s*\[?(\d+\.\d+\.\d+)\]?/m)?.[1];
      if (top && front.version && top !== front.version) {
        fail(`CHANGELOG.md top entry is ${top}, SKILL.md says ${front.version}`);
      }
    }
    if (front.version) note(`version ${front.version}`);
  }

  // 3. every relative link resolves
  const links = [...skill.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)].map((m) => m[1]);
  const broken = links.filter((href) => !/^https?:/.test(href) && !existsSync(join(ROOT, href.split('#')[0])));
  for (const href of broken) fail(`SKILL.md links to a missing file: ${href}`);
  note(`${links.length} links checked`);
}

// 4. language modules
for (const lang of LANGUAGES) {
  for (const module of MODULES) {
    const path = join(ROOT, 'references', lang, module);
    if (!existsSync(path)) {
      fail(`missing module references/${lang}/${module}`);
      continue;
    }
    const contents = readFileSync(path, 'utf8').trim();
    if (contents.length < 200) fail(`references/${lang}/${module} looks empty (${contents.length} chars)`);
    if (!contents.startsWith('# ')) fail(`references/${lang}/${module} does not start with a heading`);
  }
}

const core = join(ROOT, 'references', 'core', 'craft.md');
if (!existsSync(core)) fail('missing references/core/craft.md');

// 5. prompt-size budgets: routine work loads SKILL.md plus one rules module;
// the deep audit is conditional and has its own ceiling.
if (existsSync(skillPath)) {
  const skillWords = wordCount(readFileSync(skillPath, 'utf8'));
  for (const lang of LANGUAGES) {
    const rules = join(ROOT, 'references', lang, 'rules.md');
    if (!existsSync(rules)) continue;
    const loaded = skillWords + wordCount(readFileSync(rules, 'utf8'));
    if (loaded > DEFAULT_PROMPT_WORD_LIMIT) {
      fail(`${lang}: default prompt is ${loaded} words, limit is ${DEFAULT_PROMPT_WORD_LIMIT}`);
    } else {
      note(`${lang}: default prompt ${loaded}/${DEFAULT_PROMPT_WORD_LIMIT} words`);
    }
  }
}
if (existsSync(core)) {
  const deepWords = wordCount(readFileSync(core, 'utf8'));
  if (deepWords > DEEP_AUDIT_WORD_LIMIT) {
    fail(`deep audit is ${deepWords} words, limit is ${DEEP_AUDIT_WORD_LIMIT}`);
  } else {
    note(`deep audit ${deepWords}/${DEEP_AUDIT_WORD_LIMIT} words`);
  }
}

// 6. the banned lists still parse into something usable
const { parseBanned } = await import('../detector/lib/parse-banned.js');
for (const lang of LANGUAGES) {
  const path = join(ROOT, 'references', lang, 'banned.md');
  if (!existsSync(path)) continue;
  const { entries } = parseBanned(path, lang);
  const kinds = new Set(entries.map((e) => e.kind));
  for (const kind of ['vocabulary', 'phrase', 'opener']) {
    if (!kinds.has(kind)) fail(`references/${lang}/banned.md has no parseable ${kind} section`);
  }
  if (entries.length < 50) fail(`references/${lang}/banned.md parsed only ${entries.length} entries`);
  else note(`${lang}: ${entries.length} banned entries`);
}

// 7. numbers quoted in the documentation still match the files
const counts = {};
for (const lang of LANGUAGES) {
  const path = join(ROOT, 'references', lang, 'banned.md');
  if (!existsSync(path)) continue;
  const { entries } = parseBanned(path, lang);
  const patterns = join(ROOT, 'references', lang, 'patterns.md');
  counts[lang] = {
    vocabulary: entries.filter((e) => e.kind === 'vocabulary').length,
    phrase: entries.filter((e) => e.kind === 'phrase').length,
    opener: entries.filter((e) => e.kind === 'opener').length,
    total: entries.length,
    rewrites: existsSync(patterns)
      ? (readFileSync(patterns, 'utf8').match(/^###\s+\d+\./gm) ?? []).length
      : 0,
  };
}

const readmePath = join(ROOT, 'README.md');
if (existsSync(readmePath)) {
  const readme = readFileSync(readmePath, 'utf8');
  const NAMES = { English: 'en', Russian: 'ru', Ukrainian: 'uk' };

  for (const [name, lang] of Object.entries(NAMES)) {
    const row = readme.match(new RegExp(`^\\|\\s*${name}\\s*\\|([^\\n]*)\\|\\s*$`, 'm'));
    if (!row) {
      fail(`README has no counts row for ${name}`);
      continue;
    }
    const cells = row[1].split('|').map((c) => Number(c.trim()));
    const expected = counts[lang];
    if (!expected) continue;
    const actual = [expected.vocabulary, expected.phrase, expected.opener, expected.rewrites];
    if (cells.length !== actual.length || cells.some((c, i) => c !== actual[i])) {
      fail(`README row for ${name} says ${cells.join('/')}, files say ${actual.join('/')} — run npm run stats`);
    }
  }

  const range = readme.match(/(\d+) to (\d+) matchable\s+entries per language/);
  if (range) {
    const totals = Object.values(counts).map((c) => c.total);
    const low = Math.min(...totals);
    const high = Math.max(...totals);
    if (Number(range[1]) !== low || Number(range[2]) !== high) {
      fail(`README claims ${range[1]}–${range[2]} entries per language, files hold ${low}–${high}`);
    }
  } else {
    fail('README no longer states the per-language entry range in the expected wording');
  }
  note('README counts match the reference files');
}

// 8. relative links resolve in every document, and nothing points at the npm
// package `aislop`, which belongs to someone else
const DOCS = ['README.md', 'CONTRIBUTING.md', 'CHANGELOG.md', 'docs/architecture.md', 'docs/detector.md', 'docs/adding-a-language.md'];
for (const doc of DOCS) {
  const path = join(ROOT, doc);
  if (!existsSync(path)) continue;
  const text = readFileSync(path, 'utf8');
  // links inside code blocks are illustrations, not links to follow
  const prose = text.replace(/```[\s\S]*?```/g, '');

  for (const [, href] of prose.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
    if (/^https?:|^#/.test(href)) continue;
    const relative = href.split('#')[0];
    const target = doc.includes('/') ? join(ROOT, doc, '..', relative) : join(ROOT, relative);
    if (!existsSync(target)) fail(`${doc} links to a missing file: ${href}`);
  }

  // CHANGELOG records the mistake of pointing at that package, so it is allowed
  // to name it; anything instructional is not
  if (doc !== 'CHANGELOG.md' && /\bnp[xm]\s+(?:i\s+|install\s+)?aislop\b/.test(text)) {
    fail(`${doc} tells the reader to install "aislop" from npm — that name belongs to an unrelated package`);
  }
}

for (const line of notes) console.log(`  ${line}`);
if (problems.length === 0) {
  console.log('validate-skill: ok');
  process.exit(0);
}
for (const problem of problems) console.error(`validate-skill: ${problem}`);
process.exit(1);
