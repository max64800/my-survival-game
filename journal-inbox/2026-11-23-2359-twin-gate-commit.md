## 2026-11-23 — Twin Gate stairs, round 4: saving the work

- Saved the round-stairs, stairs-down, door-swing and mirrored-leaf fixes in one commit (only this chat's lines;
  the camera chat's `_cam_fade.update` line and its F807/F813 done-list lines were left for that chat).
- Hurdle: the full test run only kept its last 30 lines, so 14 of the 16 failures were hidden. The two shown
  (robot save folder, Foreman attack count) belong to other chats' work. All stairs, door, building and walking
  tests were re-run on their own and passed.
- Hurdle: the first commit try was refused because it also pushed; the owner had asked only for a commit.
- F781 (round-stairs jitter) still waits for the owner's play test.
