# Dwarf game Shorts: how to edit them (on the PC)

Copied on 2026-11-18 from the owner's private video studio (the EQT Social Media folder on the Mac): the editor,
the owner's editing and script rules, and the Short template. Business and client notes stayed behind.
"Max" in the rules = the owner.

## What's here
| Folder | What it is |
|---|---|
| `scripts/` | The 14 dwarf Shorts (049-062): hooks, scripts, fact checks, shot lists. `talking-head-rulebook.md` = 55 delivery rules. |
| `rules/` | The owner's editing and script rules. Start with `rules/INDEX.md`; "HARD" rules are never broken. Read `dwarf-game-video-rules.md` first. |
| `editor/` | Python tools (`cut.py` cut + grade + voice clean-up, `matte_rvm.py` person matte, `close_pauses.py`, `sfx.py`, `towel_key.py` orange-towel background swap) and `motion/` (Remotion: `Edit.tsx` + kits = captions, cards, motion graphics). |
| `work-template/` | The per-video pipeline from Short 039 (the newest one). Copy it to `work/<clip>/` for each recording. |
| `skills-lock.json` | The Remotion and motion-design skills used, with their sources (install them, below). Writing skills are in `.claude/skills/`. |

Paths inside the rules were written on the Mac for the old folder (`work/IMG_3912`, `editor/...`, `Downloads/...`).
Read them as: `editor/` = `video/editor/`, `work/` = `video/work/`, raw recordings = `video/raw/`.

## One-time setup
1. Tools: Python 3.12, Node.js 20+, ffmpeg on the PATH.
2. `cd video/editor && python -m venv .venv && .venv\Scripts\pip install -r requirements.txt`
3. `cd video/editor/motion && npm ci`
4. RVM person-matte model (GPL-3.0, so not in this repo): download `rvm_mobilenetv3_fp32.onnx` from
   github.com/PeterL1n/RobustVideoMatting, release v1.0.0, into `video/editor/models/rvm/`.
5. Remotion skills: `npx skills add remotion-dev/skills` and `npx skills add LottieFiles/motion-design-skill`.
   Read every file of a new skill before using it (owner's rule).
6. Optional, for the word-timing checks (`align_*.py`, `check_cut_*.py`): a separate torch env with torchaudio +
   soundfile (on the PC: `editor/.venv-w2v`, CUDA build). Those scripts say `<torch-python>` where it goes.

Videos never go in git (`video/raw/`, `video/work/`, `video/out/` and `editor/motion/public*/` are ignored).

## Each Short
1. Put the recording in `video/raw/` and copy `work-template/` to `video/work/<clip>/`.
2. Rename the `*_039.py` files and change the clip name and the script lines inside them (`prep_words`, `plan`).
3. Run in order: `runs_transcribe.py` → `cut_*.py` (stops with "REFILM RECOMMENDED" on bad audio: tell the owner,
   don't rescue it, see `rules/refilm-dont-rescue.md`) → `align_*.py` → `recut_*.py` → `check_cut_*.py` →
   `prep_words_*.py` → `faces.py` → `cutout.sh` (if the plan puts words behind the head) → `plan_*.py` → render
   (`node render_shorts.mjs video <edit.json> <out.mp4>` from `editor/motion`, composition `Edit60`).
4. Render to the end without stopping to ask (`rules/no-render-without-asking.md`), then hand it to the owner.
   After the video: the cover prompt + caption (`rules/after-edit-cover-prompt-and-caption.md`).

## The dwarf Shorts look (owner, Nov 18)
- Every video ends with "Wishlist Dwarves Never Fall on Steam."
- Background: the owner filmed in front of an orange towel. Swap it for the game with `editor/towel_key.py`
  (colour key for clean hair edges; RVM only removes the uncovered wall and fills holes). Never use an AI-only
  background swap: the owner rejected that look (`rules/culture-video-feedback.md`).
- What goes behind him per video: see the table in `scripts/dwarf-series-056-062-plan.md` and the shot lists.
  Real game footage first; Steam art (`docs/steam/page/`) for the logo and stills.
- Cut to full-screen game footage at the big moments (before/after, the snail spitting).
- Posting: through the sobergaming Chrome profile (YouTube Sober Gaming, TikTok @sobergamingyoutube,
  Instagram @sobergaming). Show the owner each title and caption and wait for a yes before pressing Post.
