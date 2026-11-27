## 2026-11-27 18:30 — Copper armour round 17: face frame repainted, black vs gold-brown edges (F914)

**What we did**
- The owner spotted that the frame round the eyes and the cheek guards were still shiny copper after round 16 made every other edge black.
- Removed the separate copper "face" paint, so the whole face frame, nose guard and cheek guards now use the edge colour.
- Added a switch to the build script (`trim=black` or `trim=gold`) so we can make the same armour with two edge colours. Both are matte.
- Put both side by side on the 3D page (v20): gold-brown left, black right. The game has the black one for now.

**Mistakes and hurdles**
- Claude's mistake: in round 16 Claude kept the face frame copper on purpose (so the dark eye slits would still show) but did not tell the owner clearly, so it looked forgotten. Lesson: when a change skips one part, say so in the message, not only in a page note.
- The first gold try `(0.3, 0.15, 0.035)` came out pale tan, nearly khaki, in the game light. It went darker and warmer `(0.17, 0.085, 0.016)` to look like old gold-brown.
- Publishing: removing the old picture-model files from the page was refused because Claude had not read them this chat. They were left in place (the page no longer loads them); they get removed when the set is approved.

**Checks:** the hand-built armour fit test passes.
