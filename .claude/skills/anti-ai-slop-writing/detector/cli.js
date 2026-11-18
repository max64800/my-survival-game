#!/usr/bin/env node
/**
 * aislop — command line front end for the detector.
 *
 *   aislop draft.md
 *   aislop posts/ --lang ru --severity medium
 *   cat draft.txt | aislop - --format json
 *   aislop README.md --max 0        # exit 1 on any finding
 */

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, extname, relative } from 'node:path';
import process from 'node:process';

import { detect, LANGUAGES, SEVERITIES } from './index.js';

const TEXT_EXTENSIONS = new Set(['.md', '.markdown', '.txt', '.mdx']);

const USAGE = `aislop — flag AI writing patterns in English, Russian and Ukrainian

Usage
  aislop <file|directory>... [options]
  cat draft.md | aislop -

Options
  --lang <en|ru|uk|auto>    output language (default: auto-detect per file)
  --severity <high|medium|low>
                            minimum severity to report (default: low)
  --only <rule,rule>        report only these rules
  --ignore <rule,rule>      skip these rules
  --format <pretty|json>    output format (default: pretty)
  --max <n>                 exit 1 when findings exceed n
  --quiet                   summary only, no per-finding lines
  --help                    this text

Exit codes
  0  within budget      1  over budget      2  bad usage or unreadable input`;

function parseArgs(argv) {
  const options = { paths: [], format: 'pretty', severity: 'low', max: Infinity, quiet: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const next = () => {
      const value = argv[++i];
      if (value === undefined) fail(`missing value for ${arg}`);
      return value;
    };
    switch (arg) {
      case '--help':
      case '-h':
        console.log(USAGE);
        process.exit(0);
        break;
      case '--lang':
        options.lang = next();
        break;
      case '--severity':
        options.severity = next();
        break;
      case '--only':
        options.only = next().split(',').map((s) => s.trim()).filter(Boolean);
        break;
      case '--ignore':
        options.ignore = next().split(',').map((s) => s.trim()).filter(Boolean);
        break;
      case '--format':
        options.format = next();
        break;
      case '--max':
        options.max = Number(next());
        break;
      case '--quiet':
        options.quiet = true;
        break;
      default:
        if (arg.startsWith('--')) fail(`unknown option ${arg}`);
        options.paths.push(arg);
    }
  }
  if (options.lang && options.lang !== 'auto' && !LANGUAGES.includes(options.lang)) {
    fail(`--lang must be one of auto, ${LANGUAGES.join(', ')}`);
  }
  if (!SEVERITIES.includes(options.severity)) {
    fail(`--severity must be one of ${SEVERITIES.join(', ')}`);
  }
  if (!['pretty', 'json'].includes(options.format)) fail('--format must be pretty or json');
  if (Number.isNaN(options.max)) fail('--max needs a number');
  return options;
}

function fail(message) {
  console.error(`aislop: ${message}\n\n${USAGE}`);
  process.exit(2);
}

function collect(paths) {
  const files = [];
  const walk = (path) => {
    const info = statSync(path);
    if (info.isDirectory()) {
      for (const entry of readdirSync(path)) {
        if (entry.startsWith('.') || entry === 'node_modules') continue;
        walk(join(path, entry));
      }
    } else if (TEXT_EXTENSIONS.has(extname(path).toLowerCase())) {
      files.push(path);
    }
  };
  for (const path of paths) {
    try {
      walk(path);
    } catch (error) {
      fail(`cannot read ${path}: ${error.message}`);
    }
  }
  return files;
}

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    fail('no input on stdin');
    return '';
  }
}

const COLOR = process.stdout.isTTY && !process.env.NO_COLOR;
const paint = (code, text) => (COLOR ? `\u001b[${code}m${text}\u001b[0m` : text);
const SEVERITY_COLOR = { high: 31, medium: 33, low: 90 };

function printPretty(results, options) {
  let total = 0;
  for (const { name, result } of results) {
    total += result.issues.length;
    if (result.issues.length === 0) {
      if (!options.quiet) console.log(`${paint(32, '✓')} ${name} — clean (${result.stats.words} words, ${result.lang})`);
      continue;
    }
    console.log(`\n${paint(1, name)} ${paint(90, `(${result.stats.words} words, ${result.lang})`)}`);
    if (!options.quiet) {
      for (const issue of result.issues) {
        const where = paint(90, `${issue.line}:${issue.column}`);
        const level = paint(SEVERITY_COLOR[issue.severity], issue.severity.padEnd(6));
        console.log(`  ${where}  ${level} ${paint(36, issue.rule)}  ${issue.message}`);
        console.log(`         ${paint(90, issue.excerpt)}`);
      }
    }
    const { high, medium, low } = result.stats.bySeverity;
    console.log(
      `  ${paint(90, `${result.issues.length} findings — ${high} high, ${medium} medium, ${low} low; ${result.stats.per1000} per 1000 words`)}`,
    );
  }
  const files = results.length;
  console.log(`\n${total} findings in ${files} file${files === 1 ? '' : 's'}`);
  return total;
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  const detectOptions = {
    lang: options.lang,
    only: options.only,
    ignore: options.ignore,
    severity: options.severity,
  };

  const results = [];
  const useStdin = options.paths.length === 0 || options.paths.includes('-');
  if (useStdin) {
    results.push({ name: '<stdin>', result: detect(readStdin(), detectOptions) });
  }

  for (const file of collect(options.paths.filter((p) => p !== '-'))) {
    const text = readFileSync(file, 'utf8');
    const shown = relative(process.cwd(), file);
    const name = !shown || shown.startsWith('..') ? file : shown;
    results.push({ name, result: detect(text, detectOptions) });
  }

  if (results.length === 0) fail('no readable input files');

  let total;
  if (options.format === 'json') {
    total = results.reduce((sum, r) => sum + r.result.issues.length, 0);
    console.log(JSON.stringify({ files: results, total }, null, 2));
  } else {
    total = printPretty(results, options);
  }

  process.exit(total > options.max ? 1 : 0);
}

main();
