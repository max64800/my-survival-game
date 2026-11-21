# Hit feel plan (F594)

Owner, Nov 21: "feel every hit; a good combo stuns or drops them; crits". Research: `docs/research/Melee hit feedback design.md`.
Build one step at a time; the owner plays each before the next. Keep "co-op ready": host decides stun/knockdown/crit,
everyone shows it (`MonsterManager.request_attack` -> `_hurt_monster` -> `_ev_hit`).

## Owner's picks (Nov 21)
- Crits: **earned only**. Remove the random roll (`Combat.CRIT` table, roll in `monster_manager.gd request_attack`).
- Stun meter: **shown by the enemy** (sway + dizzy stars near full), **no bar**.
- Knockdown: **normal enemies only**. Elites (`elite = true`, leaders, crested variants) and bosses only stun.

## Today (code survey)
- Stun meter: `src/combat/stun_meter.gd` (max = `Monsters.*.stun`, e.g. skeleton 80, rock beetle 70; stun 3 s from
  `monster.gd:104`; immune 2 s after; decays 8/s after 2.5 s idle). Fill = `Combat.stun_value(w, heavy, tier)`,
  from `light_stun`/`heavy_stun` in `Combat.WEAPONS` (sword light 6) -> ~14 sword hits to stun a skeleton.
- Hit fx: `_ev_hit` (monster_manager.gd ~1607): hit-stop 0.06/0.11 s, shake (hitter only), sparks, sound, number.
  `monster.gd hit_flash()` 0.16 s, `rig.hit()` = one "Hit_A" flinch, squash tween; `monster.knock()` 1.8-5 m/s.
- Damage bonuses (`combat.gd`): SNEAK 2.0, STUNNED 1.5, CRUSH 2.0 (first heavy/finisher on a stunned enemy), RIPOSTE 1.3;
  combo multipliers in WEAPONS (sword [1.0, 1.3, 1.8]). One-handed weapons have no heavy (F519): finishers do that job.

## Steps
1. **Fast stuns (Valheim-style).** Stun fill = damage dealt × weapon stun factor (blunt ~1.5, slash 1.0, pierce ~0.8).
   Meter max = ~45% of max HP (normal), more for elites/bosses (tune). Target: one full sword combo stuns a fresh
   skeleton; a mace in ~2/3 of a combo. Keep parry stun. Test: hits-to-stun per weapon vs skeleton/beetle/spider.
2. **Feel every hit.** Every hit rocks the enemy back (small step back ~0.3 m + flinch), the combo finisher shoves
   harder with a longer freeze (~0.15 s) and a deeper sound. Meter above ~70%: enemy sways, dizzy stars (reuse
   `CHARGE_STARS`). Stunned: a clear dazed pose for the whole stun, not just one flinch.
3. **Knockdowns.** Heavy hit or finisher on a stunned normal enemy: it falls for ~2-3 s (skeletons: the floor pose +
   "Skeletons_Awaken_Floor" rise; bugs flip on their backs), free hits while down, then up. Elites/bosses: stun only.
4. **Earned crits.** No random crits. Crit (×1.75, "Critical!") on: hit from behind, stunned, knocked down. Biggest
   bonus counts (they don't stack), as today.
5. **No cheap stun lock.** After a stun the safe time grows (2 s, then 4 s, 6 s if stunned again within ~10 s), shared
   by all players (it's per monster). Bosses: only heavy hits / finishers / parries fill the meter.
