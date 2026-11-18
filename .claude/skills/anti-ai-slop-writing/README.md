# Anti-AI-Slop Writing

[![CI](https://github.com/GitVoytenko/anti-ai-slop-writing/actions/workflows/ci.yml/badge.svg)](https://github.com/GitVoytenko/anti-ai-slop-writing/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Node](https://img.shields.io/badge/node-%3E%3D18-brightgreen.svg)](package.json)

A cross-agent writing skill for natural English, Russian and Ukrainian prose.
It works with Claude Code, Codex and other agents that support the Agent Skills
format. A zero-dependency linter is included for optional mechanical checks.

The skill improves writing rather than promising detector evasion. It preserves
facts and the author's voice, removes generic scaffolding, and treats stylistic
signals as context-dependent evidence rather than proof of authorship.

## What changed in v3

Routine work now loads `SKILL.md` and one short language module. The deeper
craft audit, long word lists and rewrite examples stay out of context unless
the task needs them. The previous instruction load was roughly 4,500–4,900
words; the default is now 783–816 words, about 82–84% less.

The editing model changed too:

- preserve meaning, commitments and distinctive voice before polishing;
- make the minimum effective edit instead of rebuilding every paragraph;
- judge clusters and repetition instead of banning one dash, word or triad;
- never invent anecdotes, opinions, slang or mistakes to perform humanity;
- return only the finished prose unless the user asks for an audit.

## Example

The useful fact in this draft is buried under generic framing:

> In today's fast-moving digital landscape, our comprehensive platform empowers
> teams to unlock the full potential of their data. Onboarding now takes three
> days instead of two weeks.

The skill keeps the fact and removes the wrapper:

> Onboarding used to take two weeks. It takes three days now.

Russian and Ukrainian use their own rules. Grammatical тире is normal in both
languages, and Ukrainian gets a dedicated check for Russian and English calques.
An English punctuation rule is never copied across blindly.

## Install

### One clone for Claude Code and Codex

Keep one repository checkout and link both agents to it:

```bash
git clone https://github.com/GitVoytenko/anti-ai-slop-writing.git ~/Developer/skills/anti-ai-slop-writing
ln -s ~/Developer/skills/anti-ai-slop-writing ~/.claude/skills/anti-ai-slop-writing
ln -s ~/Developer/skills/anti-ai-slop-writing ~/.codex/skills/anti-ai-slop-writing
```

With this layout, a pull in the repository updates the skill for both agents.
Restart or reload the agent session so it rebuilds its skill catalog.

If you need only one agent, clone directly into its skills directory:

```bash
git clone https://github.com/GitVoytenko/anti-ai-slop-writing.git ~/.claude/skills/anti-ai-slop-writing
# or
git clone https://github.com/GitVoytenko/anti-ai-slop-writing.git ~/.codex/skills/anti-ai-slop-writing
```

Claude Desktop / Cowork can import the folder as a skill. An uploaded copy does
not follow later Git changes automatically; upload it again after an update.

## Runtime layout

```text
SKILL.md                       shared fast-pass rules and routing
references/
  core/craft.md               optional deep audit
  en/  ru/  uk/
    rules.md                  short module loaded for that language
    banned.md                 detector vocabulary; not loaded by default
    patterns.md               examples and maintenance reference
detector/                     optional Node.js linter
```

The default path is deliberately short. For a routine email or post, the agent
reads only `SKILL.md` and `references/<lang>/rules.md`. It reads
`references/core/craft.md` for explicit audits, important long-form copy or a
rewrite that remains generic after the first pass. The word lists and example
catalogs remain available without taxing every request.

Current detector sources, counted by `npm run stats`:

| Language | Vocabulary | Phrases | Openers | Rewrite pairs |
| --- | --- | --- | --- | --- |
| English | 70 | 39 | 16 | 5 |
| Russian | 75 | 39 | 18 | 10 |
| Ukrainian | 101 | 40 | 17 | 10 |

That is 125 to 158 matchable entries per language. Ukrainian has the longest
list because it also covers common Russian and English calques.

See [docs/architecture.md](docs/architecture.md) for the ownership boundaries
and [docs/adding-a-language.md](docs/adding-a-language.md) for a new language.

## Optional detector

The linter runs on Node 18 or newer and has no dependencies. It parses the
`banned.md` files at runtime, so the human-readable lists remain the source of
truth.

```bash
npx github:GitVoytenko/anti-ai-slop-writing draft.md
```

Or install from the repository:

```bash
npm install GitVoytenko/anti-ai-slop-writing

aislop draft.md
aislop posts/ --lang ru --severity medium
cat draft.txt | aislop -
aislop README.md --max 0
```

```js
import { detect } from 'anti-ai-slop-writing';

const { issues, stats } = detect(text, { lang: 'uk' });
```

Detector findings are review prompts. A clean run means the mechanical checks
found nothing; it does not certify good writing or identify who wrote it.
[docs/detector.md](docs/detector.md) documents every rule and limitation.

## Development

```bash
npm test
npm run lint:skill
npm run self-scan
npm run check
```

`npm run check` runs the detector tests, validates skill links and version
agreement, and checks the repository's prose against the recorded budget in
[PROOF.md](PROOF.md).

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md) explains list syntax, severity conventions
and language ports. Tests include both generic fixtures the detector should
catch and ordinary prose it must leave alone.

## Credits

The English list draws on Wikipedia's [Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
and [Carnegie Mellon research](https://www.cmu.edu/dietrich/news/news-stories/2025/february/large-language-models-writing-text.html)
on lexical and grammatical differences in model output. Russian and Ukrainian
sources are recorded in their `patterns.md` files.

MIT licensed. See [LICENSE](LICENSE).
