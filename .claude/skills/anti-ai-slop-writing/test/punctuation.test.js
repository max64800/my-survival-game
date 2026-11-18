import { test } from 'node:test';
import assert from 'node:assert/strict';

import { detect } from '../detector/index.js';

const rules = (text, options) => detect(text, options).issues.map((i) => i.rule);

test('English em dashes have a budget of one per 500 words', () => {
  const one = 'The build broke — again.';
  const three = 'The build broke — again. We rolled back — quickly. Nobody — nobody at all — noticed.';
  assert.equal(rules(one, { lang: 'en' }).includes('em-dash'), false);
  assert.equal(rules(three, { lang: 'en' }).includes('em-dash'), true);
});

test('grammatical тире in Russian is free', () => {
  // zero-copula dashes are required grammar, not a tell
  const grammatical = 'Киев — столица. Работа — не волк. Наш офис — три комнаты на Подоле.';
  assert.equal(rules(grammatical, { lang: 'ru' }).includes('rhetorical-dash'), false);
});

test('a copula word after the dash keeps it grammatical', () => {
  const text = 'Четыре часа без интернета — это четыре часа, когда никто не пишет.';
  assert.equal(rules(text, { lang: 'ru' }).includes('rhetorical-dash'), false);
});

test('rhetorical dashes above the budget are flagged', () => {
  const dramatic =
    'Мы долго готовили этот запуск и очень старались — но всё пошло не так. ' +
    'Клиенты ждали обновление целый месяц — и не дождались ничего. ' +
    'Команда сидела до полуночи над отчётом — зря.';
  assert.equal(rules(dramatic, { lang: 'ru' }).includes('rhetorical-dash'), true);
});

test('the "X — это не просто Y" construction is caught', () => {
  // the mirrored form, «Это не просто X — это Y», is in banned.md and reported
  // as a banned phrase instead
  assert.equal(rules('Наш сервис — это не просто инструмент.', { lang: 'ru' }).includes('not-just-construction'), true);
  assert.equal(rules('Наш сервіс — це не просто інструмент.', { lang: 'uk' }).includes('not-just-construction'), true);
  assert.equal(rules('Это не просто инструмент — это привычка.', { lang: 'ru' }).includes('banned-phrase'), true);
});

test('exclamation marks are budgeted, not banned', () => {
  assert.equal(rules('Наконец-то заработало!', { lang: 'ru' }).includes('exclamation'), false);
  assert.equal(rules('Ура! Заработало! Мы молодцы!', { lang: 'ru' }).includes('exclamation'), true);
});

test('a second ellipsis is flagged', () => {
  assert.equal(rules('Ну... ладно.', { lang: 'ru' }).includes('ellipsis'), false);
  assert.equal(rules('Ну... ладно... посмотрим...', { lang: 'ru' }).includes('ellipsis'), true);
});

test('number ranges are not dashes', () => {
  assert.equal(rules('Встреча длилась 5—7 минут, не больше.', { lang: 'ru' }).includes('rhetorical-dash'), false);
  assert.equal(rules('The migration took 5–7 minutes.', { lang: 'en' }).includes('em-dash'), false);
});
