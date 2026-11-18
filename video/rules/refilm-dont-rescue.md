---
name: refilm-dont-rescue
description: "If a raw clip has recording faults (mic dropouts, muffled/covered mic, broken or missing takes), tell Max to refilm instead of trying to fix it in the edit"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d7dfd16-5b7a-4349-92f3-cd3a865c551f
  modified: 2026-10-02T11:18:50.791Z
---

When a raw clip has recording problems, tell Max up front that it needs a refilm, name what's wrong and where, and don't spend time rescuing it in the edit.

Faults that mean "refilm":
- Mic dropouts: stretches of digital silence or loud clicks in the audio (wireless lav cutting out).
- Muffled audio: lines that are much duller than his clear lines (mic covered by collar, shirt or hand); heavy EQ rescue sounds either muffled or hissy.
- A script line with no clean take (every take has a stumble, slip or dropout).
- Whisper "phantom" or merged takes are fine to handle in the edit; those are transcription issues, not recording faults.

**Why:** on 2026-10-02 we spent a long session EQ-rescuing muffled lines and patching a mic dropout in IMG_3747; the result still wasn't good and Max decided to refilm and had the raw and cut deleted. He'd rather know immediately.

**How to apply:** run the editor's quality check (editor/cut.py prints a REFILM warning) before cutting; if it flags anything, report it with timestamps and recommend refilming those lines (or the whole video) before doing any repair work. Also remind him of the filming checklist: lav clipped outside the collar facing up, hands below it, 5-second test at the start and a check halfway. See [[video-editing-pipeline]].
