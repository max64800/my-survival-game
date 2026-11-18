# Contributing

The word lists are the part that is never finished. If you caught a phrase that
gives a model away in English, Russian or Ukrainian, that is the most useful
pull request this repository can get, and it is a one-line change.

## Setup

```bash
git clone https://github.com/GitVoytenko/anti-ai-slop-writing.git
cd anti-ai-slop-writing
npm run check    # tests, skill validation, self-scan – no install step, no dependencies
```

Node 18 or newer. There is nothing to `npm install`: the detector uses only the
standard library, and the tests run on `node:test`.

## Adding a banned word or phrase

Everything lives in `references/<lang>/banned.md`. The detector parses that file
at runtime, so a markdown edit is the whole change.

Vocabulary goes in the comma-separated list under the vocabulary heading.
Phrases and openers are one bullet each. Four things the parser understands:

```markdown
delve / delves / delving          → three separate patterns
landscape (figurative)            → a condition it cannot verify; severity drops to low
данный (→ этот)                   → the arrow becomes the suggested replacement
эпоха («в эпоху»)                 → the quoted form replaces the bare word as the pattern
```

A gloss is safe: `производить (в значении «делать»)` bans `производить` and
leaves the ordinary word `делать` alone, because the parser only promotes a
quoted example when it is built from the term itself.

Three rules of thumb before you add an entry:

1. **Never add a synonym as the fix.** «стоит отметить» → «нельзя не упомянуть»
   is the same slop wearing a hat. If a word needs replacing, the thought needs
   rewriting, and the entry should say so or say nothing.
2. **Mark the condition when there is one.** A word banned only in its figurative
   sense gets `(figurative)` or `(переносное)`, and the detector drops it to
   `low` instead of shouting at every use.
3. **Check the register.** Канцелярит belongs in legal and official documents.
   If your entry would break those, it belongs in the "what not to flag" section
   of `SKILL.md` rather than in `banned.md`.

After the edit:

```bash
npm run stats     # confirms the entry parsed
npm test
```

## Adding a rewrite pair

`references/<lang>/patterns.md` holds before/after pairs. Copy the existing
heading format, keep the "after" concrete, and do not invent a fact to make the
rewrite look better – a fabricated specific is the defect this skill exists to
prevent.

## Changing the detector

Rules live in `detector/rules/`, one file per family. Every rule change needs a
test in `test/`, and the test has to work in both directions: the pattern is
caught in a slop fixture, and ordinary writing in `test/fixtures/human/` stays
clean. The human fixtures are the load-bearing half. A rule that flags real
prose is worse than a rule that misses slop, because it teaches the writer to
flatten sentences that were fine.

Severity conventions:

| Severity | Meaning |
| --- | --- |
| `high` | unconditional. A banned phrase, a credential opener, three same-length sentences in a row. |
| `medium` | carries a suggested replacement, or narrows the word to the exact banned form. |
| `low` | banned in one sense only, and no regex can tell which sense this is. |

## Adding a language

See [docs/adding-a-language.md](docs/adding-a-language.md). Short version:
create `references/<lang>/` with the same three modules, add a routing line to
`SKILL.md`, add a slop fixture and a human fixture, register the language in
`detector/index.js`. Structural rules that need language data (clause starters,
verbal-noun endings) live in `detector/rules/structural.js`.

## Before you open the pull request

```bash
npm run check
```

That runs the tests, validates the skill structure, and re-checks the
documentation against the budget in [PROOF.md](PROOF.md). If you edited README
or docs and the self-scan went over budget, fix the prose rather than raising
the number. Raising it deliberately is fine when the added text genuinely earns
it, but the commit should say why.

The validator also keeps the documentation honest about itself. It compares the
counts table in README against the reference files, so adding a banned entry
without running `npm run stats` fails the build. It resolves every relative link
in README, CONTRIBUTING and docs. And it rejects any line telling a reader to
install `aislop` through npm. That name belongs to an unrelated package, and
this project installs from the repository.

Update `CHANGELOG.md` under `## [Unreleased]`. Version numbers live in three
places (`SKILL.md`, `package.json`, `CHANGELOG.md`) and the validator fails if
they disagree, so a release bumps all three together.
