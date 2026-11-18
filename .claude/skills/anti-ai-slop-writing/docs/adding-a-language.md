# Adding a language

A fourth language is five files and one routing line. Nothing in the existing
modules changes.

The order below matters: write the short runtime module first, then add the
detector sources and fixtures. The skill is useful without the linter; the
linter is useless without good lists.

## 1. Create the modules

```
references/<lang>/rules.md      compact runtime guidance for this language
references/<lang>/banned.md     detector vocabulary, phrases and openers
references/<lang>/patterns.md   examples, maintenance notes and sources
```

Copy the structure from an existing language rather than the content. The
Russian and Ukrainian files are the better template for an inflected language;
the English one for an analytic language.

`rules.md` is the only language file loaded for routine writing. Keep it short.
Record the few language-specific choices that change the output: register,
grammar, translation contamination and the most common generic constructions.
Do not copy punctuation bans across languages. German, for example, would need
guidance on compound nouns and verb position rather than an English dash rule.

`banned.md` needs three `##` sections: vocabulary, phrases, openers. The parser
finds them by keyword in the heading, so a heading in your own language works as
long as it contains the local word for "vocabulary", "phrases" or "openers" –
otherwise add the keyword to `SECTION_KINDS` in
`detector/lib/parse-banned.js`.

`patterns.md` gives maintainers concrete before/after cases and records the
sources behind the language port. A public-domain exemplar is useful when it
demonstrates a language-specific rhythm, but it is not loaded on routine tasks.

## 2. Route it in `SKILL.md`

One line in the language-routing list:

```markdown
- German: [references/de/rules.md](references/de/rules.md)
```

That is the whole runtime change. `npm run lint:skill` checks that the link
resolves; the detector still discovers `banned.md` through its language list.

## 3. Add fixtures

```
test/fixtures/slop/<lang>.md     text your language modules should tear apart
test/fixtures/human/<lang>.md    ordinary writing the detector must leave alone
```

Write the human fixture first, and write it badly on purpose, with the mess a
real person leaves. Uneven sentences, a fragment, an aside, a real place name.
If your detector rules fire on it, the rules are wrong, not the text.

Then add the language to the arrays in `test/fixtures.test.js`.

## 4. Teach the detector

`detector/index.js`: add the code to `LANGUAGES`.

`detector/lib/tokenize.js`: `detectLanguage` currently splits Cyrillic between
Russian and Ukrainian by the letters only one of them uses. A new script needs
its own branch; a new Latin-script language needs a signal beyond the alphabet,
usually a short list of frequent function words.

`detector/rules/structural.js`: three tables are language-keyed and each needs an
entry: `RULE_OF_THREE` (how the language joins the last item), `CLAUSE_STARTERS`
(subordinating conjunctions, so a clause is not read as a list item), and
`ROLE_OPENER`. `VERBAL_NOUN_CHAIN` applies only where bureaucratese stacks verbal
nouns; leave it `null` otherwise.

`detector/rules/punctuation.js`: `NOT_JUST` needs the local form of the "not
just X" construction. If the language uses dashes grammatically, extend
`COPULA_AFTER` with its copula words, or the linter will flag correct grammar.

`detector/lib/morphology.js`: inflected languages need their endings in
`INFINITIVE_ENDINGS` and their alphabet in `CYRILLIC_ENDING` (or a new
equivalent). For an analytic language, `morph: false` is the honest setting.

## 5. Check both directions

```bash
npm run check
```

Then read the output on your own writing, not only on the fixtures. The
question that matters is not "did it find the slop" but "did it stay quiet on
the good text". A linter that flags real prose gets ignored within a week, and
an ignored linter is worse than none: it makes the repository look checked.
