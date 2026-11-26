# Picture-to-3D armor test (owner OK'd Nov 26)
Goal: see if a GPT-made picture (`gpt_copper_armor_front_back.png`, front + back of a dwarf in copper plate) turns into a
better armor than our hand-built one (`hand_built_vs_in_game_nov26.png`, right = hand-built copper in the game).
Owner OK'd a one-off exception to "never picture-to-3D as the final model" (MODEL-RULES rule 1) for this test only.
Notes from research (Nov 26): Top 3D AI "Queen of Hearts" lesson, 3DSkillUp pirate pipeline. Recipe: clean multi-view
pictures -> generate each part separately (helmet, chest, gloves, legs, boots; ~1,500 faces each after retopo) -> fit in
Blender -> bake dents/rivets into a normal map -> texture from the picture -> rig/skin to our dwarf.
