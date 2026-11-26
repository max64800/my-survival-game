## Nov 26: Armour picture-to-3D test, part 2: the helmet, and both pieces in the game

**What we did.** Claude installed the small Hunyuan3D 2 mini on the PC, outside the repo (`C:/Users/<you>/ai3d`). It only
makes the shape (4.2 GB), takes 5 seconds per try, and uses 4.9 GB of the 8 GB graphics card. It made the helmet from the
GPT sheet with 4 seeds. Seed 1234 won, and the owner OK'd it. The fitting script (`armor_picture3d.py`) got a helmet
step: it sits on the Head bone, comes with the "hat-hair" head, and is kept outside his skull. Then came the game
copies (`game=1`): 4-5 thousand faces instead of millions, with baked colour and bump pictures. A join script
(`armor_picture3d_join.py`) puts both in `armor_copper_picture3d.glb`. The game wears them as a TEST copper look
(`DwarfRig.armor_pic3d_test`); the gauntlets and boots stay hand-built. `tools/shot_armor.gd` takes a side-by-side
picture. A 3D comparison page went up (both dwarves exported from the game, walking and mining).

Meanwhile another chat (F916) made the dwarf buff instead of fat. The two chats messaged each other: this chat waited
for that commit, then checked that its builds already sat on the committed body (no refit needed).

**Owner's verdict:** a bit better, but mix both versions. Add leg armour, make the skirt narrower, add more detail and
polish (blurry and low-poly, worst from behind), and let no shirt show anywhere. Next chat does that.

**Mistakes and hurdles (and fixes).**
- The disk had only 11.5 GB free. Claude cleared the pip download cache (8 GB), an old temp worktree and old Claude
  scratch folders, which gave 32 GB. The owner chose to leave the videos alone.
- Installing diffusers pulled a too-new huggingface_hub, which broke transformers. Fixed by pinning the older version.
- The helmet took 5 rounds. Pushing it out of the *hair mesh* gave a crinkled rim, then lumps and holes, then spikes up
  to 35 cm, because the hair locks fool any "am I inside?" test (an old note in dwarf_armor.py warned about this).
  Fix: test against a simple egg shape round his skull instead, and skip the open face.
- Claude's first message to "the buff-body chat" went to the wrong chat (the ruins one). Fixed by listing the chats again.
- The joined file carried 2 hidden stray balls ("Icosphere") from the body file. The join now keeps only `armor_*` meshes.
- In the game, the picture copper looked pale and pink. Fix: a warmer, deeper tint before the bake.
- His white shirt showed at the throat. First try: wear the hand-built leather undercoat under the new plate. That was
  worse, because it poked through the middle. The tuck-under-the-beard step had also pushed the plate into the shirt;
  now it stops 4 mm out. The throat gap itself is the picture's open neck: a small leather collar comes next.
- The 3D page files were 39 MB and 28 MB (over the 15 MB limit). Claude dropped data the page doesn't need, halved the
  pictures and split each file into text parts.
- The browser check tool was broken (missing file), so Claude took the page screenshot with Chrome from the command line.
