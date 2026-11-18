# Architecture

One repository serves two consumers without forcing the model to read the
detector's whole catalog on every writing task.

```text
SKILL.md ──────────────── fast workflow and routing
references/
  core/craft.md ───────── optional deep audit
  <lang>/rules.md ─────── short language module loaded by the model
  <lang>/banned.md ──┐
  <lang>/patterns.md  │   detector and maintenance sources
                     │
detector/ ───────────┘   read by Node.js, not by the model
```

## Runtime path

For routine prose, the model reads `SKILL.md` and the `rules.md` file for the
output language. A Russian request for an English email therefore loads the
English module.

`references/core/craft.md` is conditional. It is used for an explicit AI-tone
audit, important long-form copy, or a rewrite that remains generic after the
fast pass. The long `banned.md` and `patterns.md` files are not part of the
default prompt. If an exhaustive mechanical review is useful, the bundled
detector reads them without adding their contents to model context.

This split cuts the default instruction load while preserving the knowledge
needed for maintenance and reproducible checks.

## Ownership

`SKILL.md` owns behavior shared by every language: modes, source preservation,
minimum-effective editing, output shape and the decision to escalate from a
fast pass to a deep audit.

`references/<lang>/rules.md` owns the small set of differences that changes how
the model writes. English, Russian and Ukrainian do not share punctuation or
translation habits. Grammatical тире is normal in Russian and Ukrainian;
Ukrainian also needs checks for Russian and English calques.

`references/<lang>/banned.md` owns the detector's matchable vocabulary, phrases
and openers. `patterns.md` supplies examples and source notes for maintainers.
Neither file is a list of unconditional model prohibitions. A detector match is
a prompt to inspect context.

## Detector path

`detector/lib/parse-banned.js` turns each `banned.md` into matchable entries.
Adding an entry updates the linter without duplicating it in JavaScript.

```text
mask.js                blanks protected regions while preserving offsets
tokenize.js            sentences, words, offsets and language guess
morphology.js          inflection-aware matching for Russian and Ukrainian
rules/lexical.js       vocabulary, phrase and opener matches
rules/structural.js    repeated rhythm, triads, parataxis and nominalisations
rules/punctuation.js   punctuation frequency heuristics
rules/formatting.js    repeated formatting habits
index.js               orchestration, filtering and statistics
cli.js                 file walking, output formats and exit codes
```

Lexical rules see masked text, so code, links and quotations do not become
findings. Structural checks also ignore Markdown decoration and table syntax.

## Limits

The detector can count a phrase or repeated shape. It cannot decide whether a
contrast is necessary, a semicolon suits the author, a scene carries emotional
weight or a legal formula belongs in the document. Even a mechanically clean
draft may be vague or voiceless.

The detector is therefore a review aid and CI floor, not an authorship test or
quality certificate. The skill makes the final contextual decision.
