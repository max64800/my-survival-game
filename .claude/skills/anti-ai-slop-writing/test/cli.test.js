import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const CLI = fileURLToPath(new URL('../detector/cli.js', import.meta.url));
const SLOP = fileURLToPath(new URL('fixtures/slop/ru.md', import.meta.url));
const HUMAN = fileURLToPath(new URL('fixtures/human/ru.md', import.meta.url));

function run(args, input) {
  try {
    const stdout = execFileSync('node', [CLI, ...args], {
      encoding: 'utf8',
      input,
      env: { ...process.env, NO_COLOR: '1' },
    });
    return { code: 0, stdout };
  } catch (error) {
    return { code: error.status, stdout: error.stdout ?? '', stderr: error.stderr ?? '' };
  }
}

test('clean file exits 0 even with --max 0', () => {
  const { code, stdout } = run([HUMAN, '--max', '0']);
  assert.equal(code, 0);
  assert.match(stdout, /clean/);
});

test('slop file exits 1 when it exceeds the budget', () => {
  assert.equal(run([SLOP, '--max', '0']).code, 1);
  assert.equal(run([SLOP, '--max', '500']).code, 0);
});

test('json output is machine readable', () => {
  const { stdout } = run([SLOP, '--format', 'json']);
  const parsed = JSON.parse(stdout);
  assert.equal(parsed.total > 0, true);
  assert.equal(parsed.files[0].result.lang, 'ru');
  assert.equal(typeof parsed.files[0].result.issues[0].line, 'number');
});

test('stdin is accepted', () => {
  const { stdout } = run(['-', '--lang', 'ru', '--format', 'json'], 'В современном мире всё меняется.');
  const parsed = JSON.parse(stdout);
  assert.equal(parsed.total, 1);
});

test('a directory is walked', () => {
  const dir = fileURLToPath(new URL('fixtures/human/', import.meta.url));
  const { stdout } = run([dir, '--format', 'json']);
  assert.equal(JSON.parse(stdout).files.length, 3);
});

test('bad usage exits 2', () => {
  assert.equal(run([SLOP, '--lang', 'de']).code, 2);
  assert.equal(run([SLOP, '--nonsense']).code, 2);
});

test('--only and --severity narrow the report', () => {
  const only = JSON.parse(run([SLOP, '--only', 'banned-opener', '--format', 'json']).stdout);
  assert.equal(only.files[0].result.issues.every((i) => i.rule === 'banned-opener'), true);

  const high = JSON.parse(run([SLOP, '--severity', 'high', '--format', 'json']).stdout);
  assert.equal(high.files[0].result.issues.every((i) => i.severity === 'high'), true);
});

test('--help explains itself and exits 0', () => {
  const { code, stdout } = run(['--help']);
  assert.equal(code, 0);
  assert.match(stdout, /aislop <file\|directory>/);
});
