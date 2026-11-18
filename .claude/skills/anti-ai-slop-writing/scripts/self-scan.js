#!/usr/bin/env node
/**
 * Runs the detector against this repository's own prose and writes PROOF.md.
 *
 * A repository that tells people how to write should survive its own linter.
 * The budget in PROOF.md is the contract: CI runs `--check` and fails if the
 * documentation drifts past it.
 *
 *   node scripts/self-scan.js          regenerate PROOF.md
 *   node scripts/self-scan.js --check  compare against the recorded budget
 *
 * references/**\/banned.md and patterns.md are excluded on purpose: one is a
 * list of banned words, the other quotes the bad version of every rewrite.
 */

import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join, relative } from 'node:path';

import { detect } from '../detector/index.js';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const PROOF = join(ROOT, 'PROOF.md');
const BUDGET_MARKER = /<!--\s*budget:\s*(\d+)\s*-->/;

const TARGETS = ['README.md', 'CONTRIBUTING.md', 'docs'];
const SKIP = new Set(['PROOF.md', 'CHANGELOG.md', 'CODE_OF_CONDUCT.md']);

function collect(target) {
  const path = join(ROOT, target);
  if (!existsSync(path)) return [];
  if (statSync(path).isDirectory()) {
    return readdirSync(path).flatMap((entry) => collect(join(target, entry)));
  }
  if (!path.endsWith('.md') || SKIP.has(relative(ROOT, path))) return [];
  return [path];
}

const files = TARGETS.flatMap(collect).sort();
const results = files.map((file) => ({
  name: relative(ROOT, file),
  // Low-severity findings are contextual review hints. The repository gate
  // enforces only medium and high issues so intentional style does not fail CI.
  result: detect(readFileSync(file, 'utf8'), { severity: 'medium' }),
}));

const total = results.reduce((sum, r) => sum + r.result.issues.length, 0);
const words = results.reduce((sum, r) => sum + r.result.stats.words, 0);
const check = process.argv.includes('--check');

if (check) {
  if (!existsSync(PROOF)) {
    console.error('self-scan: PROOF.md is missing — run `npm run self-scan` and commit it');
    process.exit(1);
  }
  const recorded = Number(readFileSync(PROOF, 'utf8').match(BUDGET_MARKER)?.[1] ?? NaN);
  if (Number.isNaN(recorded)) {
    console.error('self-scan: PROOF.md has no budget marker');
    process.exit(1);
  }
  console.log(`self-scan: ${total} findings across ${files.length} files, budget ${recorded}`);
  for (const { name, result } of results) {
    for (const issue of result.issues) {
      console.log(`  ${name}:${issue.line}:${issue.column}  ${issue.severity}  ${issue.rule}  ${issue.message}`);
    }
  }
  if (total > recorded) {
    console.error(`self-scan: over budget by ${total - recorded} — fix the prose or update PROOF.md deliberately`);
    process.exit(1);
  }
  process.exit(0);
}

const severity = results.reduce(
  (acc, r) => {
    for (const level of ['high', 'medium', 'low']) acc[level] += r.result.stats.bySeverity[level];
    return acc;
  },
  { high: 0, medium: 0, low: 0 },
);
const severityLine = `${severity.high} high, ${severity.medium} medium, ${severity.low} low`;

const rows = results.map(({ name, result }) => {
  const { high, medium, low } = result.stats.bySeverity;
  return `| \`${name}\` | ${result.lang} | ${result.stats.words} | ${high} | ${medium} | ${low} |`;
});

const details = results
  .filter((r) => r.result.issues.length > 0)
  .map(({ name, result }) => {
    const lines = result.issues.map(
      (issue) => `- \`${name}:${issue.line}:${issue.column}\` **${issue.severity}** ${issue.rule} — ${issue.message}`,
    );
    return `### ${name}\n\n${lines.join('\n')}`;
  });

const proof = `# Self-scan

<!-- budget: ${total} -->

The detector run against this repository's own documentation at medium severity
or higher. Regenerate with
\`npm run self-scan\`; CI runs \`node scripts/self-scan.js --check\` and fails if
the count climbs above the budget recorded above.

Low-severity review hints are not a CI gate. Excluded by design:
\`references/*/banned.md\` (a list of banned words) and
\`references/*/patterns.md\` (each entry quotes the bad version before the good
one). Linting those would measure the wrong thing.

**${total} findings across ${files.length} files, ${words} words** — ${severityLine}.

| File | Language | Words | High | Medium | Low |
| --- | --- | --- | --- | --- | --- |
${rows.join('\n')}

${details.length > 0 ? `## Findings\n\n${details.join('\n\n')}\n` : 'No findings.\n'}`;

writeFileSync(PROOF, proof, 'utf8');
console.log(`self-scan: ${total} findings across ${files.length} files → PROOF.md`);
