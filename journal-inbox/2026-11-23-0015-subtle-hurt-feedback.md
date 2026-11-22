## Nov 23: Subtle "you got hurt" feedback (F695 redone)

**What we did.** The owner found the full-border hurt effects "too much, it goes on the entire screen".
After a big research report on how games show getting hurt (`docs/research/Hurt screen feedback research.md`),
the owner picked four small signals instead of one big screen effect:
1. **Ghost health bar:** a pale strip behind the red fill shows what you just lost, waits 0.6 s, then drains
   (real time, so hit-stop can't freeze it).
2. **Dwarf body flash:** the dwarf glows pale for a blink, like monsters do when you hit them.
3. **Thin red edge, big hits only:** the rim is a third as wide, at most 35% strength, fades in 0.4 s, and only
   shows for hits of 10% of your health or more. Poison/fire/cold glows are fainter.
4. **Camera bump plus slider:** a small shake when hurt (smaller than when you land a hit), and a "Camera shake"
   slider in Settings (0 = no shaking at all, saved in settings.cfg). It scales all camera shake.
One hook (`hud.gd` `_on_hurt`) drives all four, only for this computer's player.

**Mistakes and hurdles.**
- The 6-option page shown before was too much: every option covered the whole border. Lesson: for hurt
  feedback, put the signal on the HUD, the character and the camera, not across the screen.
- A test compared a faded value to exactly 0 and failed on a tiny rounding leftover; switched it to "close to 0".
- I thought only 6 of 15 checks ran; the test runner counts tests, not checks. All passed.
