# Model check (the rules in `docs/art/MODEL-RULES.md`, measured)

Run it on your models **before saving**. It opens each `.glb` in Blender and measures the real surfaces.

```
blender --background --factory-startup --python tools/model_check/check_models.py -- build/wall__cut_stone tanning_rack
blender --background --factory-startup --python tools/model_check/check_models.py -- build            (a whole folder)
blender --background --factory-startup --python tools/model_check/check_models.py -- report=docs/art/model-check.md   (everything)
```

| Check | What it means | Rule |
|---|---|---|
| FLOAT | A part touches nothing (more than 1 cm from everything) and doesn't stand on the ground. Ropes, straps, symbols and leaves are parts too. Says which material, where, and how far off. | every part touching |
| SHIMMER | Two surfaces facing the same way in the same place (closer than 1.5 mm), where you can see them. Faces hidden under other parts and bottoms on the ground don't count. | 2 |
| OUTLINE | Building pieces: something sticks past the piece's box (the 2 m grid) or its triangle, by more than 5 mm. Sizes come from `src/build/pieces.gd`. | 3 |
| ROOF | Sloped roof pieces: panel thickness (15-25 cm, 8-30 allowed), filled underneath, holes you can see the sky through. | 4 |
| SCRIPT | No build script in `tools/asset_forge` makes this model. | 1 |

The game's own auto-checks (`tools\run_tests.bat only=test_model_rules`) check the build menu rules
(roofs per style, one round doorway, copper only for decor, wall decor on walls) and rule 1.
