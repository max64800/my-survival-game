import { test } from 'node:test';
import assert from 'node:assert/strict';

import { detect } from '../detector/index.js';

const rules = (text, options) => detect(text, options).issues.map((i) => i.rule);

test('three sentences of the same length are flagged', () => {
  const flat =
    'Команда работала над проектом несколько месяцев подряд. ' +
    'Разработчики писали код и тестировали новые функции. ' +
    'Дизайнеры создавали макеты и прототипы интерфейсов.';
  assert.equal(rules(flat, { lang: 'ru' }).includes('uniform-sentence-length'), true);
});

test('uneven sentences pass', () => {
  const uneven =
    'Проект делали полгода. ' +
    'Больше всего времени съел не код, а согласования: дизайнеры трижды переделывали прототип, потому что юристы каждый раз находили, к чему придраться. ' +
    'Код написали за месяц.';
  assert.equal(rules(uneven, { lang: 'ru' }).includes('uniform-sentence-length'), false);
});

test('a run of short declaratives reads as parataxis', () => {
  const choppy = 'We shipped it. It broke. We rolled back. Nobody noticed.';
  assert.equal(rules(choppy, { lang: 'en' }).includes('parataxis'), true);
});

test('an actual list of three is flagged, a subordinate clause is not', () => {
  assert.equal(
    rules('Мы предлагаем скорость, качество и надёжность.', { lang: 'ru' }).includes('rule-of-three'),
    true,
  );
  assert.equal(
    rules('Календарь висит на стене, хотя он и врёт через раз.', { lang: 'ru' }).includes('rule-of-three'),
    false,
  );
});

test('a list of three never spans a sentence boundary', () => {
  const across = 'Он купил хлеб, молоко. И сыр тоже взял.';
  assert.equal(rules(across, { lang: 'ru' }).includes('rule-of-three'), false);
});

test('credential openers are caught in all three languages', () => {
  assert.equal(rules('As a marketer with ten years of experience, I know this.', { lang: 'en' }).includes('role-opener'), true);
  assert.equal(rules('Как маркетолог с десятилетним стажем, я знаю это.', { lang: 'ru' }).includes('role-opener'), true);
  assert.equal(rules('Як фахівець із продажів, я знаю це.', { lang: 'uk' }).includes('role-opener'), true);
});

test('verbal-noun chains are caught in Russian and Ukrainian', () => {
  assert.equal(rules('Проводится внедрение решения задач.', { lang: 'ru' }).includes('verbal-noun-chain'), true);
  assert.equal(rules('Здійснюється впровадження рішення завдань.', { lang: 'uk' }).includes('verbal-noun-chain'), true);
});

test('flat rhythm needs enough text before it reports', () => {
  const short = 'Короткий текст. Ещё одно предложение.';
  assert.equal(rules(short, { lang: 'ru' }).includes('flat-rhythm'), false);
});
