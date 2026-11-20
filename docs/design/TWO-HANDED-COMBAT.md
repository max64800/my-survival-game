# Two-handed weapons and sword + shield: how the dwarf holds and swings them (F389)

Research, Nov 19, 2026 (dwarf-animations Claude, chat 5), after the owner rejected the KayKit two-handed moves
("the stance is wrong, the attacks are wrong, the hands are wrong"). The owner's reference: a photo of a warrior
with a long axe: left hand at the very end of the handle by the left hip, right hand high near the head by the right
shoulder, the handle on a slant across the body. The owner wants it simple: one stance, 2-3 swings on repeat.

## Hands (great axe, great maul)
- Bottom hand (left) at the very end of the handle, always. It is the hinge.
- Top hand (right) high, 60-75% up the handle: hands ~60-80 cm apart on a 1.2 m handle (scale down for the dwarf's
  shorter weapons). https://legendarystrength.com/?p=10143, https://myarmoury.com/talk/viewtopic.php?p=348771
- Power swings: the top hand slides down to meet the bottom hand just before the hit (sledgehammer / splitting
  swing), and slides back up on recovery. https://www.hunker.com/13413973/proper-way-to-swing-a-sledgehammer
- Fast swings and the stance: hands stay apart (pollaxe guards, Le Jeu de la Hache:
  https://www.thearma.org/spotlight/NotesLEJEUDELAHACHE.htm).
- Why KayKit failed: its clips keep both hands together at the end all the time.

## Stance (the owner's photo: a diagonal guard; Valheim, Mordhau, Kingdom Come use it)
- Left fist low by the left hip, a little in front of the belly; right fist up in front of the right shoulder.
- Handle across the chest bottom-left to top-right, 10-15 cm in front of chest and beard (never through them).
- Head beside/above the right shoulder. Body 20-30 degrees side-on (left shoulder forward), feet wide, knees soft.

## Swings (Valheim's battleaxe chain: two wide swings, then an overhead; https://hostedgg.com/wiki/valheim/battleaxe)
- A. Diagonal chop: wind-up head behind the right shoulder, body twisted right; hit: head passes in front at belly
  height, body untwists, right fist pushes, left fist pulls to the hip; ends low by the left knee.
- B. Rising return sweep: from A's end back up to the right, flatter, hands apart; ends near the stance.
- C. Overhead slam (slower finisher): both fists above and behind the head; right hand slides down to the left;
  both fists come down in front of the belly, head hits the ground ahead, knees bend; right hand slides back up.
- Heavy weapons: slower wind-up and recovery (https://www.slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks).

## One-handed weapon + shield (Dark Souls, Valheim, For Honor)
- Stance: left forearm across the front, elbow ~90 degrees near the ribs, shield face forward and a little in, top
  edge at beard height; weapon in the right hand by the right hip/shoulder, behind the shield's right edge.
- Swings: 1. forehand diagonal (right ear down to left hip, passing right of the shield); 2. backhand flat sweep
  (left hip to right, waist height; shield pulls a little left). The shield arm stays still.
- Block: shield up to eye level, pushed ~15 cm forward, slight crouch; weapon pulled back by the right hip.

## Free packs (public repo: the raw files get published)
- No free pack found with a good great axe / maul set that we may publish.
- Quaternius UAL 1+2 (CC0, used: no two-handed moves). KayKit (CC0, tried, rejected).
- Mixamo: raw files may not be redistributed: not OK for the public repo. Rokoko free mocap, CMU mocap: unclear.
  Bandai Namco dataset: non-commercial: out. Kevin Iglesias free melee: no license stated: out.
- OpenGameArt "Modular RPG Characters": said to be CC0, not confirmed.

## Plan recommended by the research: hand-made key poses
- "Two-point handle": the left fist fixed at the handle's end, the right fist at a sliding spot on the handle. Key
  where each fist sits relative to the chest; arm IK (DwarfFist `_reach`) puts the arms there.
- Automatic check: the handle stays at least 10 cm in front of the chest and beard.
- Poses: stance; chop wind-up; chop hit; chop follow-through; sweep hit; slam wind-up; slam hit; shield stance and
  block. Loop A, B, C.
