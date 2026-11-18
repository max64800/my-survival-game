import { test } from 'node:test';
import assert from 'node:assert/strict';

import { detect } from '../detector/index.js';

const rules = (text, options) => detect(text, options).issues.map((i) => i.rule);
const messages = (text, options) => detect(text, options).issues.map((i) => i.message);

test('Russian inflections of a banned word are caught', () => {
  for (const sentence of [
    'Данный подход мы обсудили.',
    'В данном контексте это неважно.',
    'Мы отказались от данного решения.',
  ]) {
    assert.equal(rules(sentence, { lang: 'ru' }).includes('banned-word'), true, sentence);
  }
});

test('a verb keeps its stem across conjugations', () => {
  assert.equal(rules('Команда осуществляет внедрение.', { lang: 'ru' }).includes('banned-word'), true);
  assert.equal(rules('Ми здійснюємо підтримку.', { lang: 'uk' }).includes('banned-word'), true);
});

test('English single words match their -s and -ing forms', () => {
  assert.equal(rules('The report underscores the risk.', { lang: 'en' }).includes('banned-word'), true);
  assert.equal(rules('We are fostering collaboration.', { lang: 'en' }).includes('banned-word'), true);
});

test('a stem does not bleed into an unrelated word', () => {
  // «данный» must not fire on «дань», «эпоха» must not fire on «эпос»
  assert.deepEqual(rules('Он отдал дань уважения. Это эпос, а не роман.', { lang: 'ru' }), []);
});

test('openers only count at the start of a sentence', () => {
  assert.equal(rules('Конечно, мы это сделаем.', { lang: 'ru' }).includes('banned-opener'), true);
  assert.equal(rules('Мы, конечно, это сделаем.', { lang: 'ru' }).includes('banned-opener'), false);
});

test('punctuation inside a listed phrase is optional', () => {
  // banned.md carries «Стоит отметить, что...»; both spellings have to match
  assert.equal(rules('Стоит отметить, что цифры сходятся.', { lang: 'ru' }).includes('banned-phrase'), true);
  assert.equal(rules('Стоит отметить что цифры сходятся.', { lang: 'ru' }).includes('banned-phrase'), true);
});

test('a suggested fix reaches the message', () => {
  const text = messages('Данный отчёт готов.', { lang: 'ru' }).join(' ');
  assert.match(text, /use этот instead/);
});

test('overlapping hits collapse into the longest one', () => {
  const { issues } = detect('В современном мире всё меняется.', { lang: 'ru' });
  assert.equal(issues.filter((i) => i.rule.startsWith('banned-')).length, 1);
  assert.match(issues[0].message, /В современном мире/);
});

test('severity filtering drops the conditional entries', () => {
  // both words are banned only "как филлер", a condition the detector cannot check
  const text = 'Наш эффективный подход учитывает актуальные запросы.';
  assert.equal(rules(text, { lang: 'ru' }).length > 0, true);
  assert.deepEqual(rules(text, { lang: 'ru', severity: 'high' }), []);
});

test('language is detected when not given', () => {
  assert.equal(detect('В современном мире всё меняется.').lang, 'ru');
  assert.equal(detect('Це не просто інструмент, а звичка.').lang, 'uk');
  assert.equal(detect('In today\'s digital landscape, teams thrive.').lang, 'en');
});

test('an unknown language is rejected loudly', () => {
  assert.throws(() => detect('text', { lang: 'de' }), /unsupported language/);
});

test('adjective stems reach every case form', () => {
  // «даний» declines to «даного»: cutting one letter would leave «дани» and miss it
  assert.equal(rules('Впровадження даного рішення.', { lang: 'uk' }).includes('banned-word'), true);
  assert.equal(rules('Даний сервіс працює.', { lang: 'uk' }).includes('banned-word'), true);
});

test('homographs of a banned stem are left alone', () => {
  // «данные» is data, not the канцелярит «данный» — every technical text has it
  assert.deepEqual(rules('Наши данные показывают рост.', { lang: 'ru' }), []);
  assert.deepEqual(rules('По данным опроса, половина ушла.', { lang: 'ru' }), []);
  assert.deepEqual(rules('Наші дані показують зростання.', { lang: 'uk' }), []);
});
