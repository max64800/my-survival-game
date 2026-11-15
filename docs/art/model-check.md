# Model check results

Made by `tools/model_check/check_models.py` (rules: `docs/art/MODEL-RULES.md`).

CHECKED 496 models: 255 ok, 241 with problems (FLOAT 46, OUTLINE 160, ROOF 26, SHIMMER 133)

| Model | Problem | Details |
|---|---|---|
| build/arch__clay_brick | SHIMMER | brick_b on brick_c at (0.81, 0.76, -0.18), 717 cm² · brick_b on brick_b at (-0.89, 0.76, -0.18), 717 cm² · brick_b on brick_b at (0.69, 0.31, -0.20), 504 cm² (+9 more) |
| build/arch__clay_brick | OUTLINE | 1.0 cm above the top at (-0.13, 1.01, 0.18) |
| build/arch__copper_ingot | SHIMMER | copper_c on copper_b at (-0.04, 0.76, -0.20), 1196 cm² · copper_c on copper_b at (0.77, 0.29, 0.20), 909 cm² · copper_c on copper_b at (-0.75, 0.21, 0.20), 909 cm² (+6 more) |
| build/arch__copper_ingot | OUTLINE | 2.0 cm past the front (z+) at (-1.02, 0.06, 0.22) · 2.0 cm past the back (z-) at (-1.02, 0.06, -0.22) · 2.0 cm past the right side (x+) at (1.02, 0.06, 0.22) (+2 more) |
| build/arch__cut_stone | SHIMMER | stone_a on stone_a at (0.89, 0.82, 0.20), 1144 cm² · stone_b on stone_b at (0.69, 0.31, -0.20), 918 cm² · stone_b on stone_a at (-0.68, 0.91, 0.20), 880 cm² (+7 more) |
| build/arch__cut_stone | OUTLINE | 1.0 cm above the top at (-0.13, 1.01, 0.18) |
| build/arch__plank_root | SHIMMER | wood_b on wood_a at (-0.81, 0.66, 0.20), 936 cm² · wood_b on wood_b at (0.69, 0.31, -0.20), 923 cm² · wood_b on wood_c at (0.33, 0.85, -0.20), 490 cm² (+1 more) |
| build/arch__plank_root | OUTLINE | 1.0 cm past the front (z+) at (-1.01, 0.10, 0.21) · 1.0 cm past the back (z-) at (-1.01, 0.10, -0.21) · 1.0 cm past the right side (x+) at (1.01, 0.86, 0.21) (+2 more) |
| build/arch_doorway__clay_brick | SHIMMER | limestone_dark on brick_dark at (1.00, 0.08, -0.04), 6346 cm² · limestone_dark on brick_dark at (-1.00, 0.08, 0.04), 6346 cm² · brick_c on brick_c at (-0.51, 1.83, -0.16), 202 cm² (+26 more) |
| build/arch_doorway__clay_brick | OUTLINE | 22.0 cm above the top at (-0.07, 2.22, 0.18) · 3.0 cm past the front (z+) at (-0.07, 1.88, 0.18) · 3.0 cm past the back (z-) at (-0.07, 2.22, -0.18) |
| build/arch_doorway__copper_ingot | OUTLINE | 23.0 cm above the top at (-0.09, 2.23, 0.17) · 4.0 cm past the front (z+) at (-0.09, 1.95, 0.19) · 4.0 cm past the back (z-) at (-0.09, 1.95, -0.19) |
| build/arch_doorway__cut_stone | SHIMMER | charcoal_+0.50 on stone_b at (1.00, 0.22, -0.04), 5850 cm² · charcoal_+0.50 on stone_b at (-1.00, 0.22, 0.04), 5850 cm² |
| build/arch_doorway__cut_stone | OUTLINE | 22.1 cm above the top at (0.13, 2.22, 0.16) · 6.3 cm past the right side (x+) at (1.06, 1.74, -0.11) · 4.5 cm past the front (z+) at (0.02, 1.99, 0.20) (+2 more) |
| build/arch_doorway__plank_root | OUTLINE | 23.0 cm above the top at (-0.09, 2.23, 0.17) · 4.0 cm past the front (z+) at (-0.09, 1.95, 0.19) · 4.0 cm past the back (z-) at (-0.09, 1.95, -0.19) |
| build/banner__copper_ingot | FLOAT | copper_a/copper_c at (0.00, 1.94, -0.02), 111x9x8 cm, 7.3 cm from the rest |
| build/banner__copper_ingot | OUTLINE | 6.0 cm past the right side (x+) at (0.56, 1.97, -0.02) · 5.3 cm past the left side (x-) at (-0.55, 1.93, -0.02) · 1.2 cm past the back (z-) at (-0.53, 1.93, -0.06) |
| build/banner__plank_root | FLOAT | copper_b/wood_dark at (0.00, 1.94, -0.02), 111x9x8 cm, 7.3 cm from the rest |
| build/banner__plank_root | OUTLINE | 6.0 cm past the right side (x+) at (0.56, 1.97, -0.02) · 5.3 cm past the left side (x-) at (-0.55, 1.93, -0.02) · 1.2 cm past the back (z-) at (-0.53, 1.93, -0.06) |
| build/barrel__plank_mushroom | SHIMMER | copper_b on copper_b at (0.03, 0.94, 0.03), 12 cm² · copper_b on copper_b at (-0.03, 0.94, 0.03), 12 cm² |
| build/barrel__plank_mushroom | OUTLINE | 7.5 cm past the front (z+) at (-0.01, 0.19, 0.42) · 6.0 cm above the top at (-0.10, 0.96, 0.02) · 0.9 cm past the right side (x+) at (0.36, 0.29, -0.00) (+2 more) |
| build/barrel__plank_root | SHIMMER | copper_b on copper_b at (0.03, 0.94, 0.03), 12 cm² · copper_b on copper_b at (-0.03, 0.94, 0.03), 12 cm² |
| build/barrel__plank_root | OUTLINE | 7.5 cm past the front (z+) at (-0.01, 0.19, 0.42) · 6.0 cm above the top at (-0.10, 0.96, 0.02) · 0.9 cm past the right side (x+) at (0.36, 0.29, -0.00) (+2 more) |
| build/battlement__cut_stone | OUTLINE | 8.7 cm past the left side (x-) at (-1.09, 0.23, -0.15) · 2.7 cm past the front (z+) at (-0.85, 0.47, 0.23) · 1.0 cm past the back (z-) at (-1.00, 0.45, -0.21) (+1 more) |
| build/beam__clay_brick | OUTLINE | 1.8 cm past the front (z+) at (-0.95, 0.08, 0.17) |
| build/beam__copper_ingot | OUTLINE | 2.0 cm past the front (z+) at (0.90, -0.02, 0.17) · 2.0 cm past the back (z-) at (0.90, -0.02, -0.17) · 2.0 cm below the bottom at (0.90, -0.02, 0.17) (+1 more) |
| build/beam__cut_stone | OUTLINE | 1.8 cm past the front (z+) at (0.95, 0.22, 0.17) |
| build/beam__plank_root | OUTLINE | 1.4 cm above the top at (0.78, 0.31, -0.00) · 1.4 cm past the front (z+) at (0.78, 0.15, 0.16) · 1.4 cm past the back (z-) at (0.78, 0.15, -0.16) (+3 more) |
| build/beam_half__clay_brick | OUTLINE | 1.8 cm past the front (z+) at (-0.45, 0.08, 0.17) · 1.5 cm past the left side (x-) at (-0.52, 0.07, 0.14) · 1.5 cm past the right side (x+) at (0.52, 0.23, 0.14) |
| build/beam_half__copper_ingot | OUTLINE | 2.0 cm past the front (z+) at (0.40, -0.02, 0.17) · 2.0 cm past the back (z-) at (0.40, -0.02, -0.17) · 2.0 cm below the bottom at (0.40, -0.02, 0.17) (+1 more) |
| build/beam_half__cut_stone | OUTLINE | 1.8 cm past the front (z+) at (0.45, 0.22, 0.17) |
| build/beam_half__plank_root | OUTLINE | 1.4 cm below the bottom at (-0.25, -0.01, -0.00) · 1.4 cm above the top at (0.28, 0.31, -0.00) · 1.4 cm past the front (z+) at (0.28, 0.15, 0.16) (+3 more) |
| build/brace__clay_brick | OUTLINE | 3.4 cm above the top at (0.89, 2.03, 0.11) · 3.4 cm past the right side (x+) at (1.03, 1.89, -0.11) · 3.4 cm past the left side (x-) at (-1.03, 0.11, 0.11) (+3 more) |
| build/brace__copper_ingot | OUTLINE | 3.4 cm above the top at (0.89, 2.03, 0.11) · 3.4 cm past the right side (x+) at (1.03, 1.89, -0.11) · 3.4 cm past the left side (x-) at (-1.03, 0.11, 0.11) (+3 more) |
| build/brace__cut_stone | OUTLINE | 3.4 cm above the top at (0.89, 2.03, 0.11) · 3.4 cm past the right side (x+) at (1.03, 1.89, -0.11) · 3.4 cm past the left side (x-) at (-1.03, 0.11, 0.11) (+3 more) |
| build/brace__plank_root | OUTLINE | 3.4 cm above the top at (0.89, 2.03, 0.11) · 3.4 cm past the right side (x+) at (1.03, 1.89, -0.11) · 3.4 cm past the left side (x-) at (-1.03, 0.11, 0.11) (+3 more) |
| build/ceiling_panel__clay_brick | SHIMMER | limestone_dark on rooftile_c at (-0.33, 0.11, 0.33), 4901 cm² · limestone_dark on rooftile_b at (0.33, 0.11, -0.33), 4901 cm² · limestone_dark on brick_dark at (0.33, 0.11, -0.33), 4901 cm² (+6 more) |
| build/ceiling_panel__clay_brick | OUTLINE | 0.5 cm above the top at (-0.24, 0.26, -0.13) |
| build/ceiling_panel__copper_ingot | OUTLINE | 5.0 cm above the top at (0.79, 0.30, 1.00) · 2.0 cm past the right side (x+) at (1.02, 0.26, -1.00) · 2.0 cm past the left side (x-) at (-1.02, 0.25, 1.00) |
| build/ceiling_panel__cut_stone | SHIMMER | basalt_b on charcoal_+0.50 at (0.95, 0.11, 0.73), 79 cm² |
| build/ceiling_panel__cut_stone | OUTLINE | 1.2 cm above the top at (0.02, 0.26, 0.55) |
| build/ceiling_panel__plank_root | OUTLINE | 2.0 cm above the top at (0.92, 0.27, 0.89) · 1.0 cm below the bottom at (0.55, -0.01, 0.33) |
| build/crate__plank_mushroom | SHIMMER | iron_a on mushwood_dark at (-0.46, 0.80, 0.44), 6 cm² |
| build/crate__plank_mushroom | OUTLINE | 3.0 cm past the right side (x+) at (0.48, 0.01, 0.47) · 3.0 cm past the left side (x-) at (-0.48, 0.01, 0.47) · 3.0 cm past the front (z+) at (-0.47, 0.01, 0.48) (+1 more) |
| build/crate__plank_root | SHIMMER | iron_a on wood_dark at (-0.46, 0.80, 0.44), 6 cm² |
| build/crate__plank_root | OUTLINE | 3.0 cm past the right side (x+) at (0.48, 0.01, 0.47) · 3.0 cm past the left side (x-) at (-0.48, 0.01, 0.47) · 3.0 cm past the front (z+) at (-0.47, 0.01, 0.48) (+1 more) |
| build/door__clay_brick | OUTLINE | 2.6 cm past the front (z+) at (0.26, 0.72, 0.09) · 1.8 cm past the left side (x-) at (-0.52, 1.27, 0.02) · 1.4 cm past the back (z-) at (-0.44, 0.26, -0.07) |
| build/door__copper_ingot | OUTLINE | 11.2 cm past the front (z+) at (0.33, 0.90, 0.17) · 3.5 cm past the back (z-) at (0.38, 0.29, -0.09) |
| build/door__cut_stone | OUTLINE | 2.6 cm past the front (z+) at (0.26, 0.72, 0.09) · 1.9 cm past the left side (x-) at (-0.52, 0.27, 0.05) · 1.4 cm past the back (z-) at (-0.44, 0.26, -0.07) |
| build/door__plank_root | OUTLINE | 2.6 cm past the front (z+) at (0.26, 0.72, 0.09) · 1.9 cm past the left side (x-) at (-0.52, 1.27, 0.02) · 1.4 cm past the back (z-) at (-0.44, 0.26, -0.07) |
| build/doorway__clay_brick | SHIMMER | limestone_dark on brick_dark at (-1.00, 0.08, 0.04), 14400 cm² · brickochre_c on brick_b at (-0.47, 1.60, -0.16), 55 cm² · brick_c on brick_dark at (0.26, 1.80, -0.16), 55 cm² (+11 more) |
| build/doorway__clay_brick | OUTLINE | 3.0 cm past the front (z+) at (-0.01, 1.77, 0.18) · 3.0 cm past the back (z-) at (-0.03, 2.00, -0.18) · 1.4 cm above the top at (0.11, 2.01, -0.18) |
| build/doorway__copper_ingot | SHIMMER | copper_dark on copper_c at (0.50, 0.00, 0.03), 2572 cm² · copper_dark on copper_c at (-0.50, 0.00, -0.03), 2572 cm² · copper_dark on copper_c at (0.17, 1.80, -0.03), 1706 cm² |
| build/doorway__copper_ingot | OUTLINE | 4.5 cm past the front (z+) at (0.47, 1.47, 0.20) · 4.0 cm past the back (z-) at (-0.67, 1.81, -0.19) · 1.0 cm below the bottom at (-0.61, -0.01, 0.17) |
| build/doorway__cut_stone | SHIMMER | charcoal_+0.50 on stone_b at (1.00, 0.26, -0.04), 6170 cm² · charcoal_+0.50 on stone_b at (-1.00, 0.26, 0.04), 6170 cm² · stone_b on limestone_c at (0.39, 1.61, 0.04), 76 cm² (+1 more) |
| build/doorway__cut_stone | OUTLINE | 8.1 cm above the top at (-0.11, 2.08, 0.16) · 6.4 cm past the right side (x+) at (1.06, 1.04, 0.14) · 4.5 cm past the front (z+) at (0.02, 1.87, 0.20) (+3 more) |
| build/doorway__plank_root | SHIMMER | greywood_c on stone_a at (-0.00, 1.80, -0.02), 34 cm² · wood_b on stone_a at (-0.05, 1.80, -0.02), 22 cm² |
| build/doorway__plank_root | OUTLINE | 2.4 cm past the right side (x+) at (1.02, 1.72, -0.00) · 2.4 cm past the left side (x-) at (-1.02, 1.72, -0.00) · 1.6 cm above the top at (-0.95, 2.02, -0.07) (+1 more) |
| build/flat_roof__cut_stone | SHIMMER | charcoal_+0.50 on stone_c at (-0.33, 0.14, 0.33), 4901 cm² · charcoal_+0.50 on basalt_a at (0.33, 0.14, -0.33), 4901 cm² · basalt_b on charcoal_+0.50 at (0.76, 0.14, 0.17), 727 cm² (+1 more) |
| build/flat_roof__cut_stone | OUTLINE | 0.7 cm above the top at (0.61, 0.31, 0.56) |
| build/floor__clay_brick | SHIMMER | limestone_dark on brick_dark at (-0.33, 0.11, 0.33), 4901 cm² · limestone_dark on brick_c at (0.33, 0.11, -0.33), 4901 cm² · limestone_dark on brick_a at (-0.33, 0.11, 0.33), 4901 cm² (+15 more) |
| build/floor__copper_ingot | OUTLINE | 2.0 cm past the right side (x+) at (1.02, 0.26, -1.00) · 2.0 cm past the left side (x-) at (-1.02, 0.25, 1.00) · 1.0 cm above the top at (0.98, 0.26, 1.00) |
| build/floor__cut_stone | SHIMMER | charcoal_+0.50 on basalt_a at (-0.33, 0.11, 0.33), 4901 cm² · limestone_c on charcoal_+0.50 at (0.95, 0.11, 0.18), 191 cm² |
| build/floor__cut_stone | OUTLINE | 1.1 cm above the top at (-0.96, 0.26, 0.07) |
| build/floor__plank_root | OUTLINE | 2.0 cm above the top at (0.92, 0.27, 0.94) |
| build/floor_half__copper_ingot | OUTLINE | 2.0 cm past the right side (x+) at (1.02, 0.26, -0.50) · 2.0 cm past the left side (x-) at (-1.02, 0.25, 0.50) · 1.0 cm above the top at (0.98, 0.26, 0.50) |
| build/floor_triangle__clay_brick | SHIMMER | limestone_a on limestone_dark at (0.66, 0.11, 0.30), 453 cm² · limestone_a on limestone_dark at (0.41, 0.11, -0.13), 453 cm² · limestone_a on limestone_dark at (0.16, 0.11, 0.42), 453 cm² (+29 more) |
| build/floor_triangle__clay_brick | OUTLINE | 1.1 cm above the top at (-0.52, 0.26, 0.56) |
| build/floor_triangle__cut_stone | SHIMMER | charcoal_+0.50 on stone_a at (0.00, 0.11, 0.00), 4330 cm² · basalt_a on charcoal_+0.50 at (-0.72, 0.11, 0.39), 494 cm² · basalt_a on basalt_b at (-0.72, 0.11, 0.39), 247 cm² (+11 more) |
| build/floor_triangle__cut_stone | OUTLINE | 1.1 cm above the top at (0.24, 0.26, -0.69) |
| build/floor_triangle__plank_root | OUTLINE | 2.0 cm above the top at (0.83, 0.27, 0.51) · 1.1 cm past the left slanted edge at (-0.42, 0.07, -0.45) · 0.9 cm past the right slanted edge at (0.42, 0.07, -0.45) (+1 more) |
| build/foundation__clay_brick | SHIMMER | limestone_dark on rooftile_b at (0.33, 0.88, -0.33), 4901 cm² · limestone_dark on limestone_c at (0.33, 0.88, -0.33), 4901 cm² · limestone_dark on limestone_c at (0.33, 0.88, -0.33), 4901 cm² (+68 more) |
| build/foundation__clay_brick | OUTLINE | 2.6 cm past the front (z+) at (0.83, 0.51, 1.03) · 2.6 cm past the back (z-) at (-0.62, 0.38, -1.03) · 2.0 cm past the right side (x+) at (1.02, 0.89, 0.18) (+2 more) |
| build/foundation__copper_ingot | SHIMMER | charcoal_+1.60 on stone_b at (0.33, 0.30, -0.99), 2227 cm² · charcoal_+1.60 on stone_b at (-0.99, 0.60, 0.33), 2227 cm² · charcoal_+1.60 on stone_b at (-0.99, 0.30, -0.33), 2227 cm² (+12 more) |
| build/foundation__copper_ingot | OUTLINE | 2.0 cm past the right side (x+) at (1.02, 0.92, 1.00) · 2.0 cm past the left side (x-) at (-1.02, 0.92, 1.00) · 2.0 cm past the front (z+) at (-1.00, 0.92, 1.02) (+1 more) |
| build/foundation__cut_stone | SHIMMER | charcoal_+0.50 on stone_c at (-0.33, 0.88, 0.33), 4901 cm² · charcoal_+0.50 on brownrock_b at (0.33, 0.88, -0.33), 4901 cm² · brownrock_b on basalt_b at (-0.34, 0.02, 0.68), 505 cm² (+5 more) |
| build/foundation__cut_stone | OUTLINE | 6.0 cm past the back (z-) at (1.01, 0.02, -1.06) · 6.0 cm past the left side (x-) at (-1.06, 0.02, 0.66) · 6.0 cm past the right side (x+) at (1.06, 0.02, 0.66) (+3 more) |
| build/foundation__plank_root | OUTLINE | 2.9 cm past the right side (x+) at (1.03, 0.02, -0.87) · 2.0 cm above the top at (0.92, 1.02, 0.96) · 0.8 cm past the back (z-) at (0.68, 0.02, -1.01) |
| build/foundation_half__clay_brick | SHIMMER | limestone_dark on limestone_c at (0.33, 0.88, -0.16), 4851 cm² · limestone_dark on limestone_c at (0.33, 0.88, -0.16), 2426 cm² · limestone_dark on limestone_c at (-0.33, 0.88, 0.16), 2426 cm² (+43 more) |
| build/foundation_half__clay_brick | OUTLINE | 2.6 cm past the back (z-) at (-0.68, 0.24, -0.53) · 2.4 cm past the front (z+) at (0.82, 0.51, 0.52) · 2.0 cm past the right side (x+) at (1.02, 0.89, -0.12) (+1 more) |
| build/foundation_half__cut_stone | SHIMMER | charcoal_+0.50 on stone_a at (0.33, 0.88, -0.16), 2426 cm² · charcoal_+0.50 on brownrock_b at (-0.33, 0.88, 0.16), 2426 cm² · basalt_b on stone_a at (0.68, 0.10, 0.05), 298 cm² (+6 more) |
| build/foundation_half__cut_stone | OUTLINE | 6.0 cm past the left side (x-) at (-1.06, 0.02, 0.15) · 6.0 cm past the back (z-) at (1.01, 0.02, -0.56) · 6.0 cm past the front (z+) at (-1.00, 0.02, 0.56) (+3 more) |
| build/foundation_half__plank_root | OUTLINE | 3.1 cm past the left side (x-) at (-1.03, 0.02, 0.18) · 2.0 cm above the top at (0.92, 1.02, 0.46) |
| build/foundation_steps__clay_brick | OUTLINE | 2.0 cm past the front (z+) at (-0.98, 0.23, 1.02) · 1.0 cm past the back (z-) at (-0.24, 0.01, -1.01) |
| build/foundation_steps__cut_stone | OUTLINE | 2.0 cm past the front (z+) at (-0.98, 0.19, 1.02) · 0.9 cm past the back (z-) at (0.77, 0.33, -1.01) |
| build/foundation_steps__plank_root | SHIMMER | bark_c on stone_c at (0.96, 0.00, -0.94), 84 cm² · bark_a on stone_b at (-0.96, 0.00, -0.82), 48 cm² |
| build/foundation_steps__plank_root | OUTLINE | 7.0 cm past the left side (x-) at (-1.07, 0.02, -0.98) · 6.7 cm past the right side (x+) at (1.07, 0.02, 0.74) · 5.0 cm past the back (z-) at (-0.80, 0.02, -1.05) (+3 more) |
| build/foundation_triangle__clay_brick | SHIMMER | limestone_dark on brick_dark at (-0.67, 0.91, 0.00), 240 cm² · limestone_a on limestone_a at (0.07, 1.01, -0.72), 113 cm² · limestone_c on limestone_c at (-0.66, 1.01, 0.42), 113 cm² (+17 more) |
| build/foundation_triangle__clay_brick | OUTLINE | 15.1 cm past the front edge at (0.83, 0.78, 0.73) · 15.0 cm past the right slanted edge at (0.21, 0.28, -1.09) · 15.0 cm past the left slanted edge at (-1.05, 0.78, 0.36) (+1 more) |
| build/foundation_triangle__cut_stone | SHIMMER | limestone_b on basalt_b at (-0.01, 0.23, 0.28), 560 cm² · stone_b on basalt_b at (-0.06, 0.03, -0.66), 443 cm² · limestone_b on stone_b at (0.06, 0.01, -0.98), 128 cm² (+4 more) |
| build/foundation_triangle__cut_stone | OUTLINE | 15.1 cm past the front edge at (0.83, 0.33, 0.73) · 15.0 cm past the left slanted edge at (-1.05, 0.33, 0.36) · 14.8 cm past the right slanted edge at (0.20, 0.33, -1.10) (+2 more) |
| build/foundation_triangle__plank_root | FLOAT | iron_b/iron_c/wood_c at (-0.00, 0.96, -0.64), 45x12x17 cm, 1.0 cm from the rest |
| build/foundation_triangle__plank_root | OUTLINE | 10.0 cm past the left slanted edge at (-0.95, 0.02, 0.30) · 9.7 cm past the right slanted edge at (0.93, 0.02, 0.26) · 5.9 cm past the front edge at (-0.62, 0.02, 0.64) (+1 more) |
| build/gable_26__clay_brick | OUTLINE | 6.6 cm below the bottom at (-0.98, -0.07, 0.16) · 2.2 cm past the left side (x-) at (-1.02, 0.02, 0.16) · 2.0 cm past the front (z+) at (0.52, 0.70, 0.17) (+1 more) |
| build/gable_26__copper_ingot | OUTLINE | 10.9 cm above the top at (0.97, 1.11, 0.17) · 3.0 cm past the front (z+) at (-0.97, 0.02, 0.18) · 3.0 cm past the back (z-) at (-0.97, 0.02, -0.18) (+2 more) |
| build/gable_26__cut_stone | SHIMMER | wood_dark on stone_b at (-0.99, 0.05, -0.06), 40 cm² · charcoal_+1.60 on stone_b at (-0.99, 0.03, -0.04), 19 cm² |
| build/gable_26__cut_stone | OUTLINE | 10.9 cm above the top at (0.97, 1.11, 0.17) · 3.0 cm past the front (z+) at (-0.97, 0.02, 0.18) · 3.0 cm past the back (z-) at (-0.97, 0.02, -0.18) (+2 more) |
| build/gable_26__plank_root | OUTLINE | 1.6 cm past the right side (x+) at (1.02, 0.04, 0.05) · 1.6 cm past the left side (x-) at (-1.02, 0.04, -0.05) · 1.6 cm below the bottom at (0.85, -0.02, 0.05) |
| build/gable_45__clay_brick | SHIMMER | rooftile_c on charcoal at (0.34, 0.71, -0.16), 191 cm² · brick_a on brick_b at (0.33, 0.45, -0.17), 45 cm² · brick_b on brick_b at (0.66, 0.60, -0.17), 45 cm² (+10 more) |
| build/gable_45__clay_brick | OUTLINE | 5.9 cm below the bottom at (-0.98, -0.06, 0.16) · 4.2 cm past the left side (x-) at (-1.04, 0.00, 0.16) · 2.0 cm past the front (z+) at (-0.98, -0.04, 0.17) (+1 more) |
| build/gable_45__copper_ingot | OUTLINE | 9.7 cm above the top at (0.96, 2.10, 0.17) · 3.7 cm past the right side (x+) at (1.04, 2.02, 0.17) · 3.7 cm past the left side (x-) at (-1.04, 0.10, 0.17) (+2 more) |
| build/gable_45__cut_stone | SHIMMER | charcoal_+1.60 on stone_c at (0.78, 1.82, -0.04), 364 cm² · charcoal_+1.60 on stone_b at (-0.88, 0.16, -0.04), 364 cm² · charcoal_+1.60 on stone_b at (-0.22, 0.82, -0.04), 364 cm² (+4 more) |
| build/gable_45__cut_stone | OUTLINE | 9.7 cm above the top at (0.96, 2.10, 0.17) · 3.7 cm past the right side (x+) at (1.04, 2.02, 0.17) · 3.7 cm past the left side (x-) at (-1.04, 0.10, 0.17) (+2 more) |
| build/gable_45__plank_root | OUTLINE | 2.5 cm past the left side (x-) at (-1.03, 0.18, -0.00) · 1.6 cm past the right side (x+) at (1.02, 0.04, 0.05) · 1.6 cm below the bottom at (0.85, -0.02, 0.05) |
| build/half_wall__clay_brick | OUTLINE | 2.6 cm past the back (z-) at (0.83, 0.51, -0.18) · 2.5 cm past the front (z+) at (-0.99, 0.24, 0.17) |
| build/half_wall__cut_stone | SHIMMER | limestone_b on charcoal_+0.50 at (0.78, 1.00, -0.05), 450 cm² · limestone_b on charcoal_+0.50 at (-0.84, 1.00, -0.05), 309 cm² · limestone_b on brownrock_b at (0.97, 0.99, 0.17), 15 cm² |
| build/half_wall__cut_stone | OUTLINE | 3.4 cm past the front (z+) at (0.48, 0.43, 0.18) · 3.2 cm past the back (z-) at (0.71, 0.03, -0.18) · 0.8 cm below the bottom at (-0.70, -0.01, 0.14) (+1 more) |
| build/half_wall__plank_root | OUTLINE | 1.6 cm past the right side (x+) at (1.02, 0.04, 0.06) · 1.6 cm past the left side (x-) at (-1.02, 0.04, -0.06) · 1.6 cm above the top at (-0.95, 1.02, -0.07) (+1 more) |
| build/half_wall_diagonal__clay_brick | SHIMMER | charcoal_+1.60 on brick_c at (0.30, 0.99, 0.36), 843 cm² · charcoal_+1.60 on brick_c at (0.30, 0.99, 0.36), 843 cm² · charcoal_+1.60 on brick_c at (-0.30, 0.99, -0.36), 843 cm² (+13 more) |
| build/half_wall_diagonal__clay_brick | OUTLINE | 9.9 cm past the right side (x+) at (1.10, 0.99, 0.89) · 9.9 cm past the left side (x-) at (-1.10, 0.44, -0.89) · 9.9 cm past the front (z+) at (0.89, 0.99, 1.10) (+1 more) |
| build/half_wall_diagonal__copper_ingot | OUTLINE | 7.1 cm past the back (z-) at (-0.90, 0.02, -1.07) · 7.1 cm past the left side (x-) at (-1.07, 0.02, -0.90) · 7.1 cm past the right side (x+) at (1.07, 0.52, 0.90) (+1 more) |
| build/half_wall_diagonal__cut_stone | SHIMMER | charcoal_+1.60 on stone_b at (1.02, 0.66, 0.96), 882 cm² · charcoal_+1.60 on stone_a at (-1.02, 0.66, -0.96), 882 cm² · charcoal_+1.60 on stone_a at (-1.02, 0.66, -0.96), 882 cm² (+2 more) |
| build/half_wall_diagonal__cut_stone | OUTLINE | 11.9 cm past the right side (x+) at (1.12, 0.92, 0.87) · 11.9 cm past the left side (x-) at (-1.12, 0.92, -0.87) · 11.9 cm past the front (z+) at (0.87, 0.92, 1.12) (+1 more) |
| build/half_wall_diagonal__plank_root | SHIMMER | wood_dark on wood_dark at (-0.95, 1.00, -1.02), 1112 cm² · wood_dark on wood_dark at (0.95, 1.00, 1.02), 1112 cm² · wood_dark on wood_dark at (1.03, 0.01, 0.96), 305 cm² (+13 more) |
| build/half_wall_diagonal__plank_root | OUTLINE | 11.9 cm past the right side (x+) at (1.12, 0.02, 0.87) · 11.9 cm past the left side (x-) at (-1.12, 0.02, -0.87) · 11.9 cm past the front (z+) at (0.87, 0.02, 1.12) (+1 more) |
| build/mine_prop__clay_brick | FLOAT | iron_b at (-0.80, 2.45, 0.18), 27x27x3 cm, 1.5 cm from the rest · iron_b at (0.80, 2.45, 0.18), 27x27x3 cm, 1.5 cm from the rest |
| build/mine_prop__clay_brick | OUTLINE | 1.0 cm past the front (z+) at (-0.99, 0.02, 0.21) · 1.0 cm past the back (z-) at (-0.99, 0.02, -0.21) · 1.0 cm past the right side (x+) at (1.01, 0.02, 0.19) (+1 more) |
| build/mine_prop__copper_ingot | FLOAT | iron_c at (-0.80, 2.45, 0.18), 27x27x3 cm, 1.5 cm from the rest · iron_b at (0.80, 2.45, 0.18), 27x27x3 cm, 1.5 cm from the rest |
| build/mine_prop__copper_ingot | OUTLINE | 1.0 cm past the front (z+) at (-0.99, 0.02, 0.21) · 1.0 cm past the back (z-) at (-0.99, 0.02, -0.21) · 1.0 cm past the right side (x+) at (1.01, 0.02, 0.19) (+1 more) |
| build/mine_prop__cut_stone | FLOAT | iron_a at (-0.80, 2.45, 0.18), 27x27x3 cm, 1.5 cm from the rest · iron_b at (0.80, 2.45, 0.18), 27x27x3 cm, 1.5 cm from the rest |
| build/mine_prop__cut_stone | OUTLINE | 1.0 cm past the front (z+) at (-0.99, 0.02, 0.21) · 1.0 cm past the back (z-) at (-0.99, 0.02, -0.21) · 1.0 cm past the right side (x+) at (1.01, 0.02, 0.19) (+1 more) |
| build/mine_prop__plank_root | FLOAT | iron_c at (-0.80, 2.45, 0.18), 27x27x3 cm, 1.5 cm from the rest · iron_a at (0.80, 2.45, 0.18), 27x27x3 cm, 1.5 cm from the rest |
| build/mine_prop__plank_root | OUTLINE | 1.0 cm past the front (z+) at (-0.99, 0.02, 0.21) · 1.0 cm past the back (z-) at (-0.99, 0.02, -0.21) · 1.0 cm past the right side (x+) at (1.01, 0.02, 0.19) (+1 more) |
| build/pillar__copper_ingot | SHIMMER | copper_dark on copper_b at (-0.09, 2.00, -0.09), 650 cm² |
| build/pillar__copper_ingot | OUTLINE | 7.5 cm past the right side (x+) at (0.28, 1.87, 0.25) · 7.5 cm past the left side (x-) at (-0.28, 1.87, 0.25) · 7.5 cm past the front (z+) at (-0.25, 1.87, 0.28) (+1 more) |
| build/pillar__cut_stone | OUTLINE | 0.6 cm past the right side (x+) at (0.21, 1.82, -0.17) · 0.6 cm past the left side (x-) at (-0.21, 1.82, 0.17) · 0.6 cm past the front (z+) at (0.17, 1.82, 0.21) (+1 more) |
| build/pillar__plank_root | OUTLINE | 1.4 cm past the right side (x+) at (0.21, 0.03, -0.15) · 1.4 cm past the left side (x-) at (-0.21, 0.03, 0.15) · 0.5 cm past the front (z+) at (0.16, 0.03, 0.21) (+1 more) |
| build/railing__clay_brick | SHIMMER | brickochre_c on brickochre_b at (-0.61, 0.83, -0.02), 126 cm² · rooftile_b on rooftile_c at (-0.88, 0.80, -0.07), 55 cm² · brick_b on brick_c at (-0.26, 0.64, 0.07), 54 cm² (+2 more) |
| build/railing__clay_brick | OUTLINE | 1.5 cm past the front (z+) at (-0.99, 0.91, 0.09) · 1.5 cm past the back (z-) at (-0.99, 0.91, -0.09) |
| build/railing__copper_ingot | OUTLINE | 4.5 cm above the top at (-1.00, 1.04, 0.05) |
| build/railing__cut_stone | SHIMMER | stone_c on stone_c at (-0.99, 0.09, 0.07), 91 cm² · stone_c on stone_a at (1.00, 0.05, -0.06), 91 cm² · limestone_c on stone_a at (1.00, 0.93, 0.02), 32 cm² |
| build/railing__cut_stone | OUTLINE | 1.0 cm past the front (z+) at (-0.99, 0.89, 0.09) · 1.0 cm past the back (z-) at (-0.99, 0.89, -0.09) |
| build/railing__plank_root | OUTLINE | 2.4 cm past the right side (x+) at (1.02, 0.96, -0.00) · 2.4 cm past the left side (x-) at (-1.02, 0.90, -0.00) · 1.9 cm past the front (z+) at (0.93, 0.96, 0.09) (+3 more) |
| build/railing_diagonal__clay_brick | OUTLINE | 4.5 cm past the right side (x+) at (1.05, 1.01, 0.96) · 4.5 cm past the left side (x-) at (-1.05, 1.01, -0.96) · 4.5 cm past the front (z+) at (0.96, 1.01, 1.05) (+2 more) |
| build/railing_diagonal__copper_ingot | OUTLINE | 4.5 cm past the right side (x+) at (1.05, 1.01, 0.96) · 4.5 cm past the left side (x-) at (-1.05, 1.01, -0.96) · 4.5 cm past the front (z+) at (0.96, 1.01, 1.05) (+2 more) |
| build/railing_diagonal__cut_stone | OUTLINE | 4.5 cm past the right side (x+) at (1.05, 1.01, 0.96) · 4.5 cm past the left side (x-) at (-1.05, 1.01, -0.96) · 4.5 cm past the front (z+) at (0.96, 1.01, 1.05) (+2 more) |
| build/railing_diagonal__plank_root | OUTLINE | 4.5 cm past the right side (x+) at (1.05, 1.01, 0.96) · 4.5 cm past the left side (x-) at (-1.05, 1.01, -0.96) · 4.5 cm past the front (z+) at (0.96, 1.01, 1.05) (+2 more) |
| build/ramp__clay_brick | SHIMMER | wood_dark on brick_c at (-0.97, 0.68, -0.31), 320 cm² · wood_dark on brick_c at (0.95, 0.68, -0.31), 304 cm² · wood_dark on brick_c at (0.95, 0.68, -0.31), 163 cm² (+5 more) |
| build/ramp__clay_brick | OUTLINE | 1.6 cm past the front (z+) at (-0.99, 0.07, 1.02) · 1.6 cm past the back (z-) at (-0.99, 0.90, -1.02) · 1.1 cm below the bottom at (-0.99, -0.01, 0.98) (+2 more) |
| build/ramp__copper_ingot | SHIMMER | copper_dark on copper_b at (-0.97, 0.68, -0.31), 320 cm² · copper_dark on copper_b at (0.95, 0.68, -0.31), 304 cm² · copper_dark on copper_b at (0.95, 0.68, -0.31), 163 cm² (+5 more) |
| build/ramp__copper_ingot | OUTLINE | 1.6 cm past the front (z+) at (-0.99, 0.07, 1.02) · 1.6 cm past the back (z-) at (-0.99, 0.90, -1.02) · 1.1 cm below the bottom at (-0.99, -0.01, 0.98) (+2 more) |
| build/ramp__cut_stone | SHIMMER | wood_dark on stone_c at (-0.97, 0.68, -0.31), 320 cm² · wood_dark on stone_b at (0.95, 0.68, -0.31), 304 cm² · wood_dark on stone_c at (0.95, 0.68, -0.31), 163 cm² (+5 more) |
| build/ramp__cut_stone | OUTLINE | 1.6 cm past the front (z+) at (-0.99, 0.07, 1.02) · 1.6 cm past the back (z-) at (-0.99, 0.90, -1.02) · 1.1 cm below the bottom at (-0.99, -0.01, 0.98) (+2 more) |
| build/ramp__plank_root | SHIMMER | wood_dark on wood_b at (-0.97, 0.68, -0.31), 320 cm² · wood_dark on wood_c at (0.95, 0.68, -0.31), 304 cm² · wood_dark on wood_b at (0.95, 0.68, -0.31), 163 cm² (+5 more) |
| build/ramp__plank_root | OUTLINE | 1.6 cm past the front (z+) at (-0.99, 0.07, 1.02) · 1.6 cm past the back (z-) at (-0.99, 0.90, -1.02) · 1.1 cm below the bottom at (-0.99, -0.01, 0.98) (+2 more) |
| build/roof_26__clay_brick | SHIMMER | wood_b on rooftile_dark at (-1.00, 0.64, -0.33), 72 cm² · wood_b on rooftile_dark at (-1.00, 0.30, 0.47), 72 cm² · wood_b on rooftile_dark at (-1.00, 0.47, 0.07), 72 cm² (+7 more) |
| build/roof_26__clay_brick | OUTLINE | 6.2 cm past the front (z+) at (0.37, 0.17, 1.06) · 6.1 cm past the back (z-) at (-0.37, 0.92, -1.06) · 2.9 cm above the top at (0.34, 1.03, -1.01) |
| build/roof_26__copper_ingot | OUTLINE | 5.6 cm above the top at (-1.02, 1.06, -0.59) · 5.0 cm past the front (z+) at (-1.02, -0.01, 1.05) · 3.0 cm past the right side (x+) at (1.03, -0.01, 1.04) (+3 more) |
| build/roof_26__copper_ingot | ROOF | panel is 60 cm thick (should be 15-25 cm) · filled underneath (56 of 64 spots solid down to the floor), should be open |
| build/roof_26__cut_stone | OUTLINE | 5.6 cm above the top at (-1.02, 1.06, -0.59) · 5.0 cm past the front (z+) at (-1.02, -0.01, 1.05) · 3.0 cm past the right side (x+) at (1.03, -0.01, 1.04) (+3 more) |
| build/roof_26__cut_stone | ROOF | panel is 60 cm thick (should be 15-25 cm) · filled underneath (56 of 64 spots solid down to the floor), should be open |
| build/roof_26__plank_root | SHIMMER | shingle_a on shingle_c at (0.18, 0.79, -0.56), 471 cm² · shingle_a on shingle_c at (-0.54, 0.80, -0.56), 410 cm² · shingle_a on shingle_c at (0.17, 0.37, 0.44), 321 cm² (+20 more) |
| build/roof_26__plank_root | OUTLINE | 4.3 cm past the back (z-) at (0.75, 0.96, -1.04) · 4.3 cm past the front (z+) at (0.80, 0.11, 1.04) |
| build/roof_26__plank_root | ROOF | panel is 7 cm thick (should be 15-25 cm) |
| build/roof_26_inner__clay_brick | SHIMMER | rooftile_dark on wood_b at (-0.87, 0.89, -0.60), 102 cm² · rooftile_dark on wood_b at (-0.60, 0.83, -0.73), 102 cm² · rooftile_dark on wood_b at (0.20, 0.49, 0.07), 102 cm² (+6 more) |
| build/roof_26_inner__clay_brick | OUTLINE | 6.2 cm past the left side (x-) at (-1.06, 0.93, 0.79) · 6.1 cm past the back (z-) at (-0.39, 0.93, -1.06) · 4.5 cm above the top at (-0.92, 1.05, -0.92) (+2 more) |
| build/roof_26_inner__clay_brick | ROOF | 6 of 64 spots you can see the sky through (holes) |
| build/roof_26_inner__copper_ingot | OUTLINE | 16.6 cm past the front (z+) at (1.08, 0.01, 1.17) · 16.6 cm past the right side (x+) at (1.17, 0.01, 1.08) · 7.2 cm below the bottom at (1.13, -0.07, 1.06) (+1 more) |
| build/roof_26_inner__copper_ingot | ROOF | panel is 58 cm thick (should be 15-25 cm) · filled underneath (56 of 64 spots solid down to the floor), should be open |
| build/roof_26_inner__cut_stone | OUTLINE | 16.6 cm past the front (z+) at (1.08, 0.01, 1.17) · 16.6 cm past the right side (x+) at (1.17, 0.01, 1.08) · 7.2 cm below the bottom at (1.13, -0.07, 1.06) (+1 more) |
| build/roof_26_inner__cut_stone | ROOF | panel is 58 cm thick (should be 15-25 cm) · filled underneath (56 of 64 spots solid down to the floor), should be open |
| build/roof_26_inner__plank_root | SHIMMER | shingle_c on shingle_a at (-0.56, 0.80, 0.59), 401 cm² · shingle_c on shingle_b at (0.12, 0.65, -0.22), 331 cm² · shingle_c on shingle_b at (0.99, 0.77, -0.57), 250 cm² (+10 more) |
| build/roof_26_inner__plank_root | OUTLINE | 4.3 cm past the left side (x-) at (-1.04, 0.96, -0.41) · 4.3 cm past the back (z-) at (0.36, 0.96, -1.04) · 3.8 cm above the top at (-0.93, 1.04, -0.93) (+2 more) |
| build/roof_26_inner__plank_root | ROOF | 2 of 64 spots you can see the sky through (holes) · panel is 7 cm thick (should be 15-25 cm) |
| build/roof_26_outer__clay_brick | SHIMMER | wood_b on rooftile_dark at (-1.00, 0.64, -0.33), 72 cm² · wood_b on rooftile_dark at (-0.33, 0.64, -0.60), 72 cm² · wood_b on rooftile_dark at (0.07, 0.47, -0.20), 72 cm² (+9 more) |
| build/roof_26_outer__clay_brick | OUTLINE | 20.5 cm above the top at (-0.94, 1.20, -0.94) · 6.2 cm past the right side (x+) at (1.06, 0.17, -0.65) · 6.1 cm past the front (z+) at (-0.48, 0.16, 1.06) |
| build/roof_26_outer__clay_brick | ROOF | 6 of 64 spots you can see the sky through (holes) |
| build/roof_26_outer__copper_ingot | OUTLINE | 16.6 cm past the front (z+) at (1.08, 0.01, 1.17) · 16.6 cm past the right side (x+) at (1.17, 0.01, 1.08) · 7.2 cm below the bottom at (1.13, -0.07, 1.06) (+1 more) |
| build/roof_26_outer__copper_ingot | ROOF | panel is 31 cm thick (should be 15-25 cm) · filled underneath (26 of 64 spots solid down to the floor), should be open |
| build/roof_26_outer__cut_stone | OUTLINE | 16.6 cm past the front (z+) at (1.08, 0.01, 1.17) · 16.6 cm past the right side (x+) at (1.17, 0.01, 1.08) · 7.2 cm below the bottom at (1.13, -0.07, 1.06) (+1 more) |
| build/roof_26_outer__cut_stone | ROOF | panel is 31 cm thick (should be 15-25 cm) · filled underneath (26 of 64 spots solid down to the floor), should be open |
| build/roof_26_outer__plank_root | SHIMMER | shingle_b on shingle_b at (0.76, 0.19, -0.99), 457 cm² · shingle_c on shingle_a at (-0.21, 0.51, 0.11), 317 cm² · shingle_b on shingle_b at (0.11, 0.51, -0.53), 253 cm² (+14 more) |
| build/roof_26_outer__plank_root | OUTLINE | 4.3 cm above the top at (-0.92, 1.04, -0.92) · 4.3 cm past the right side (x+) at (1.04, 0.11, -0.03) · 4.3 cm past the front (z+) at (0.58, 0.11, 1.04) |
| build/roof_26_outer__plank_root | ROOF | 2 of 64 spots you can see the sky through (holes) · panel is 7 cm thick (should be 15-25 cm) |
| build/roof_26_ridge__clay_brick | SHIMMER | wood_b on wood_dark at (0.33, 0.07, 1.01), 110 cm² · wood_b on wood_dark at (-0.33, 0.07, -1.01), 110 cm² · wood_b on wood_dark at (0.33, 0.07, -1.00), 110 cm² (+25 more) |
| build/roof_26_ridge__clay_brick | OUTLINE | 6.0 cm past the back (z-) at (-0.08, 0.16, -1.06) · 5.9 cm past the front (z+) at (-0.63, 0.17, 1.06) · 3.5 cm above the top at (0.49, 0.54, -0.01) (+2 more) |
| build/roof_26_ridge__copper_ingot | SHIMMER | copper_b on copper_c at (-1.02, 0.35, 0.43), 2089 cm² · copper_b on copper_c at (-1.02, 0.35, -0.43), 2089 cm² · copper_b on copper_a at (-1.02, 0.30, 0.55), 2089 cm² (+1 more) |
| build/roof_26_ridge__copper_ingot | OUTLINE | 11.0 cm above the top at (-1.01, 0.61, 0.13) · 3.0 cm past the right side (x+) at (1.03, 0.51, 0.13) · 3.0 cm past the left side (x-) at (-1.03, 0.51, 0.13) (+2 more) |
| build/roof_26_ridge__copper_ingot | ROOF | panel is 40 cm thick (should be 15-25 cm) · filled underneath (32 of 64 spots solid down to the floor), should be open |
| build/roof_26_ridge__cut_stone | SHIMMER | slate_b on slate_c at (-1.02, 0.22, -0.76), 2089 cm² · slate_b on slate_c at (-1.02, 0.43, -0.22), 2089 cm² · slate_b on slate_a at (-1.02, 0.35, 0.43), 2089 cm² (+1 more) |
| build/roof_26_ridge__cut_stone | OUTLINE | 11.0 cm above the top at (-1.01, 0.61, 0.13) · 3.0 cm past the right side (x+) at (1.03, 0.51, 0.13) · 3.0 cm past the left side (x-) at (-1.03, 0.51, 0.13) (+2 more) |
| build/roof_26_ridge__cut_stone | ROOF | panel is 40 cm thick (should be 15-25 cm) · filled underneath (32 of 64 spots solid down to the floor), should be open |
| build/roof_26_ridge__plank_root | SHIMMER | shingle_a on shingle_b at (0.62, 0.28, -0.57), 408 cm² · shingle_a on shingle_c at (-0.99, 0.25, -0.56), 397 cm² · shingle_a on shingle_c at (0.48, 0.17, -0.91), 393 cm² (+21 more) |
| build/roof_26_ridge__plank_root | OUTLINE | 4.4 cm above the top at (0.73, 0.54, -0.00) · 4.3 cm past the front (z+) at (-0.98, 0.12, 1.04) · 4.3 cm past the back (z-) at (0.76, 0.12, -1.04) (+2 more) |
| build/roof_26_ridge__plank_root | ROOF | panel is 7 cm thick (should be 15-25 cm) |
| build/roof_45__clay_brick | SHIMMER | wood_b on rooftile_dark at (-1.00, 1.70, -0.78), 100 cm² · wood_b on rooftile_dark at (-1.00, 1.39, -0.44), 100 cm² · wood_b on rooftile_dark at (-1.00, 0.16, 0.89), 100 cm² (+8 more) |
| build/roof_45__clay_brick | OUTLINE | 7.3 cm past the back (z-) at (-0.08, 1.92, -1.07) · 7.2 cm past the front (z+) at (-0.92, 0.13, 1.07) |
| build/roof_45__clay_brick | ROOF | panel is 8 cm thick (should be 15-25 cm) |
| build/roof_45__copper_ingot | OUTLINE | 5.8 cm above the top at (-1.02, 2.06, -0.71) · 5.0 cm past the front (z+) at (-1.02, -0.01, 1.05) · 3.0 cm past the right side (x+) at (1.03, -0.01, 1.04) (+3 more) |
| build/roof_45__copper_ingot | ROOF | panel is 87 cm thick (should be 15-25 cm) · filled underneath (64 of 64 spots solid down to the floor), should be open |
| build/roof_45__cut_stone | OUTLINE | 5.8 cm above the top at (-1.02, 2.06, -0.71) · 5.0 cm past the front (z+) at (-1.02, -0.01, 1.05) · 3.0 cm past the right side (x+) at (1.03, -0.01, 1.04) (+3 more) |
| build/roof_45__cut_stone | ROOF | panel is 87 cm thick (should be 15-25 cm) · filled underneath (64 of 64 spots solid down to the floor), should be open |
| build/roof_45__plank_root | SHIMMER | shingle_b on shingle_a at (-0.99, 0.49, 0.59), 504 cm² · shingle_c on shingle_a at (-0.99, 0.95, 0.09), 374 cm² · shingle_c on shingle_b at (0.06, 1.65, -0.66), 336 cm² (+29 more) |
| build/roof_45__plank_root | OUTLINE | 4.1 cm past the back (z-) at (0.00, 1.87, -1.04) · 4.1 cm past the front (z+) at (0.00, 0.06, 1.04) |
| build/roof_45__plank_root | ROOF | panel is 5 cm thick (should be 15-25 cm) |
| build/roof_45_inner__clay_brick | SHIMMER | rooftile_dark on wood_b at (-0.89, 1.83, -0.67), 142 cm² · rooftile_dark on wood_b at (-0.67, 1.72, -0.77), 142 cm² · rooftile_dark on wood_b at (0.67, 0.49, 0.56), 142 cm² (+13 more) |
| build/roof_45_inner__clay_brick | OUTLINE | 7.3 cm past the left side (x-) at (-1.07, 1.92, 0.94) · 7.3 cm past the back (z-) at (-0.30, 1.92, -1.07) · 3.6 cm past the right side (x+) at (1.04, 0.17, 0.96) (+2 more) |
| build/roof_45_inner__clay_brick | ROOF | 2 of 64 spots you can see the sky through (holes) |
| build/roof_45_inner__plank_root | SHIMMER | shingle_b on shingle_a at (-0.41, 1.42, 0.21), 501 cm² · shingle_b on shingle_b at (0.09, 0.96, 0.99), 376 cm² · shingle_b on shingle_b at (-0.41, 1.42, -0.13), 307 cm² (+18 more) |
| build/roof_45_inner__plank_root | OUTLINE | 4.1 cm past the back (z-) at (0.00, 1.87, -1.04) · 4.1 cm past the left side (x-) at (-1.04, 1.95, -0.50) · 3.3 cm above the top at (-0.92, 2.03, -0.92) (+2 more) |
| build/roof_45_inner__plank_root | ROOF | 2 of 64 spots you can see the sky through (holes) · panel is 6 cm thick (should be 15-25 cm) |
| build/roof_45_outer__clay_brick | SHIMMER | wood_b on rooftile_dark at (-1.00, 1.39, -0.44), 100 cm² · wood_b on rooftile_dark at (-0.44, 1.39, -0.67), 100 cm² · wood_b on rooftile_dark at (0.89, 0.16, 0.67), 100 cm² (+14 more) |
| build/roof_45_outer__clay_brick | OUTLINE | 20.5 cm above the top at (-0.94, 2.21, -0.94) · 7.3 cm past the front (z+) at (-0.46, 0.13, 1.07) · 7.1 cm past the right side (x+) at (1.07, 0.13, 0.13) |
| build/roof_45_outer__clay_brick | ROOF | 2 of 64 spots you can see the sky through (holes) |
| build/roof_45_outer__plank_root | SHIMMER | shingle_b on shingle_b at (0.44, 0.63, -0.99), 520 cm² · shingle_b on shingle_b at (-0.25, 0.73, 0.34), 520 cm² · shingle_c on shingle_c at (0.94, 0.17, -0.99), 459 cm² (+18 more) |
| build/roof_45_outer__plank_root | OUTLINE | 4.1 cm past the right side (x+) at (1.04, 0.07, -0.71) · 4.1 cm past the front (z+) at (0.00, 0.06, 1.04) · 3.2 cm above the top at (-0.92, 2.03, -0.92) |
| build/roof_45_outer__plank_root | ROOF | panel is 6 cm thick (should be 15-25 cm) |
| build/roof_45_ridge__clay_brick | SHIMMER | rooftile_dark on wood_b at (-1.00, 0.84, -0.11), 137 cm² · rooftile_dark on wood_b at (-1.00, 0.74, 0.23), 137 cm² · rooftile_dark on wood_b at (-1.00, 0.55, -0.45), 137 cm² (+16 more) |
| build/roof_45_ridge__clay_brick | OUTLINE | 7.2 cm past the back (z-) at (-0.94, 0.12, -1.07) · 7.1 cm past the front (z+) at (-0.92, 0.13, 1.07) · 2.6 cm past the right side (x+) at (1.03, 0.88, 0.05) (+2 more) |
| build/roof_45_ridge__clay_brick | ROOF | panel is 8 cm thick (should be 15-25 cm) |
| build/roof_45_ridge__copper_ingot | SHIMMER | copper_b on copper_a at (-0.33, 0.71, 0.33), 13321 cm² · copper_b on copper_a at (-0.33, 0.41, -0.67), 13321 cm² · copper_b on copper_c at (-0.33, 0.71, 0.33), 9990 cm² (+4 more) |
| build/roof_45_ridge__copper_ingot | OUTLINE | 11.0 cm above the top at (-1.01, 1.11, 0.13) · 3.1 cm past the front (z+) at (-1.02, 0.16, 1.03) · 3.1 cm past the back (z-) at (-1.02, 0.16, -1.03) (+2 more) |
| build/roof_45_ridge__copper_ingot | ROOF | panel is 57 cm thick (should be 15-25 cm) · filled underneath (64 of 64 spots solid down to the floor), should be open |
| build/roof_45_ridge__cut_stone | SHIMMER | slate_a on slate_c at (-0.33, 0.71, 0.33), 13321 cm² · slate_a on slate_c at (-0.33, 0.41, -0.67), 13321 cm² · slate_a on slate_b at (-0.33, 0.71, 0.33), 9990 cm² (+4 more) |
| build/roof_45_ridge__cut_stone | OUTLINE | 11.0 cm above the top at (-1.01, 1.11, 0.13) · 3.1 cm past the front (z+) at (-1.02, 0.16, 1.03) · 3.1 cm past the back (z-) at (-1.02, 0.16, -1.03) (+2 more) |
| build/roof_45_ridge__cut_stone | ROOF | panel is 57 cm thick (should be 15-25 cm) · filled underneath (64 of 64 spots solid down to the floor), should be open |
| build/roof_45_ridge__plank_root | SHIMMER | shingle_c on shingle_c at (0.11, 0.38, -0.69), 370 cm² · shingle_c on shingle_a at (0.63, 0.80, -0.19), 295 cm² · shingle_c on shingle_b at (-0.25, 0.81, -0.19), 268 cm² (+29 more) |
| build/roof_45_ridge__plank_root | OUTLINE | 4.4 cm above the top at (0.73, 1.04, -0.00) · 4.2 cm past the back (z-) at (-0.02, 0.09, -1.04) · 4.2 cm past the front (z+) at (0.14, 0.08, 1.04) (+2 more) |
| build/roof_45_ridge__plank_root | ROOF | panel is 6 cm thick (should be 15-25 cm) |
| build/rug__plank_mushroom | OUTLINE | 5.0 cm past the right side (x+) at (1.05, 0.02, 0.61) · 5.0 cm past the left side (x-) at (-1.05, 0.00, -0.38) |
| build/rug__plank_root | OUTLINE | 5.0 cm past the right side (x+) at (1.05, 0.02, 0.61) · 5.0 cm past the left side (x-) at (-1.05, 0.00, -0.61) |
| build/sloped_wall__clay_brick | OUTLINE | 5.7 cm below the bottom at (-0.98, -0.06, 0.16) · 4.3 cm past the left side (x-) at (-1.04, 0.01, 0.16) · 2.0 cm past the front (z+) at (0.69, 1.63, 0.17) (+1 more) |
| build/sloped_wall__cut_stone | SHIMMER | moss_-0.00 on moss_-0.07 at (0.14, 1.01, 0.11), 35 cm² |
| build/sloped_wall__cut_stone | OUTLINE | 5.7 cm below the bottom at (-0.98, -0.06, -0.16) · 4.3 cm past the left side (x-) at (-1.04, 0.01, 0.16) · 2.0 cm past the front (z+) at (0.69, 1.63, 0.17) (+1 more) |
| build/sloped_wall__plank_root | OUTLINE | 4.3 cm past the left side (x-) at (-1.04, 0.17, -0.00) · 2.4 cm past the right side (x+) at (1.02, 1.72, -0.00) · 1.6 cm below the bottom at (0.80, -0.02, 0.08) |
| build/small_floor__copper_ingot | OUTLINE | 2.0 cm past the right side (x+) at (0.52, 0.26, -0.50) · 2.0 cm past the left side (x-) at (-0.52, 0.25, 0.50) · 1.0 cm above the top at (0.48, 0.26, 0.50) |
| build/small_floor__plank_root | FLOAT | wood_c at (0.00, 0.15, 0.12), 100x10x24 cm, 1.2 cm from the rest · wood_b at (0.00, 0.15, -0.12), 100x10x24 cm, 1.2 cm from the rest |
| build/stairs__clay_brick | OUTLINE | 2.0 cm past the front (z+) at (-0.98, 0.34, 1.02) · 1.0 cm past the back (z-) at (0.63, 1.38, -1.01) |
| build/stairs__cut_stone | OUTLINE | 2.0 cm past the front (z+) at (-0.98, 0.34, 1.02) · 0.9 cm past the back (z-) at (0.36, 0.38, -1.01) · 0.5 cm above the top at (-0.95, 2.01, -0.59) |
| build/stairs__plank_root | SHIMMER | bark_c on stone_b at (0.96, 0.00, -0.83), 70 cm² · bark_a on stone_a at (-0.84, 0.00, -0.82), 22 cm² |
| build/stairs__plank_root | OUTLINE | 8.5 cm past the right side (x+) at (1.08, 0.02, -0.81) · 7.6 cm past the left side (x-) at (-1.08, 0.02, 0.76) · 6.5 cm past the back (z-) at (0.97, 0.02, -1.06) (+3 more) |
| build/table__cut_stone | OUTLINE | 12.0 cm above the top at (0.40, 1.02, 0.04) |
| build/table__plank_root | OUTLINE | 12.0 cm above the top at (0.40, 1.02, 0.04) |
| build/wall__clay_brick | OUTLINE | 2.6 cm past the back (z-) at (0.71, 0.99, -0.18) · 2.6 cm past the front (z+) at (-0.99, 1.76, 0.18) |
| build/wall__cut_stone | SHIMMER | charcoal_+0.50 on limestone_c at (-0.33, 2.00, -0.04), 1800 cm² · limestone_b on charcoal_+0.50 at (-0.13, 2.00, -0.05), 674 cm² · limestone_b on charcoal_+0.50 at (0.78, 2.00, -0.05), 225 cm² (+1 more) |
| build/wall__cut_stone | OUTLINE | 3.4 cm past the back (z-) at (0.48, 0.43, -0.18) · 3.3 cm past the front (z+) at (0.48, 1.80, 0.18) |
| build/wall__plank_root | OUTLINE | 2.4 cm past the right side (x+) at (1.02, 1.72, -0.00) · 2.4 cm past the left side (x-) at (-1.02, 1.72, -0.00) · 1.6 cm above the top at (-0.95, 2.02, -0.07) (+1 more) |
| build/wall_diagonal__clay_brick | SHIMMER | charcoal_+1.60 on brick_b at (-1.02, 1.33, -0.96), 2873 cm² · charcoal_+1.60 on brick_c at (0.30, 1.99, 0.36), 843 cm² · charcoal_+1.60 on brick_b at (0.30, 1.99, 0.36), 843 cm² (+20 more) |
| build/wall_diagonal__clay_brick | OUTLINE | 9.9 cm past the right side (x+) at (1.10, 1.99, 0.89) · 9.9 cm past the left side (x-) at (-1.10, 0.01, -0.89) · 9.9 cm past the front (z+) at (0.89, 1.99, 1.10) (+1 more) |
| build/wall_diagonal__copper_ingot | OUTLINE | 7.1 cm past the back (z-) at (-0.90, 0.02, -1.07) · 7.1 cm past the left side (x-) at (-1.07, 0.02, -0.90) · 7.1 cm past the right side (x+) at (1.07, 0.52, 0.90) (+1 more) |
| build/wall_diagonal__cut_stone | SHIMMER | charcoal_+1.60 on stone_a at (1.02, 1.33, 0.96), 1782 cm² · charcoal_+1.60 on stone_a at (1.02, 1.33, 0.96), 1782 cm² · charcoal_+1.60 on stone_a at (-1.02, 1.33, -0.96), 1782 cm² (+4 more) |
| build/wall_diagonal__cut_stone | OUTLINE | 11.9 cm past the right side (x+) at (1.12, 1.92, 0.87) · 11.9 cm past the left side (x-) at (-1.12, 1.92, -0.87) · 11.9 cm past the front (z+) at (0.87, 1.92, 1.12) (+1 more) |
| build/wall_diagonal__plank_root | SHIMMER | wood_dark on wood_dark at (0.95, 2.00, 1.02), 392 cm² · wood_dark on wood_dark at (-0.95, 2.00, -1.02), 392 cm² · wood_dark on wood_dark at (1.03, 0.01, 0.96), 305 cm² (+13 more) |
| build/wall_diagonal__plank_root | OUTLINE | 11.9 cm past the right side (x+) at (1.12, 0.02, 0.87) · 11.9 cm past the left side (x-) at (-1.12, 0.02, -0.87) · 11.9 cm past the front (z+) at (0.87, 0.02, 1.12) (+1 more) |
| build/wall_narrow__clay_brick | SHIMMER | charcoal_+1.60 on brick_b at (-0.49, 1.33, 0.04), 2070 cm² · charcoal_+1.60 on brick_b at (-0.49, 0.67, -0.04), 1188 cm² · charcoal_+1.60 on brick_b at (0.49, 0.67, 0.04), 594 cm² (+12 more) |
| build/wall_narrow__cut_stone | SHIMMER | charcoal_+1.60 on stone_b at (-0.49, 1.33, 0.04), 1782 cm² · charcoal_+1.60 on stone_a at (-0.49, 1.33, 0.04), 1782 cm² · stone_c on charcoal_+1.60 at (0.49, 1.88, -0.04), 711 cm² (+2 more) |
| build/wall_narrow__cut_stone | OUTLINE | 3.0 cm past the front (z+) at (-0.48, 1.92, 0.18) · 3.0 cm past the back (z-) at (-0.48, 1.92, -0.18) |
| build/wall_narrow__plank_root | SHIMMER | wood_dark on wood_dark at (0.48, 2.00, 0.05), 392 cm² · wood_dark on wood_dark at (-0.48, 2.00, -0.05), 392 cm² · wood_dark on wood_c at (0.16, 2.00, 0.05), 384 cm² (+15 more) |
| build/wall_narrow__plank_root | OUTLINE | 3.0 cm past the front (z+) at (-0.48, 0.02, 0.18) · 3.0 cm past the back (z-) at (-0.48, 0.02, -0.18) |
| build/wall_sconce__copper_ingot | FLOAT | copper_b at (0.00, 0.34, 0.06), 22x2x22 cm, 3.3 cm from the rest |
| build/wall_sconce__copper_ingot | OUTLINE | 2.2 cm past the front (z+) at (0.00, 0.34, 0.17) |
| build/wall_sconce__cut_stone | FLOAT | iron_c at (0.00, 0.34, 0.06), 22x2x22 cm, 3.3 cm from the rest |
| build/wall_sconce__cut_stone | OUTLINE | 2.2 cm past the front (z+) at (0.00, 0.34, 0.17) |
| build/wall_shield__copper_ingot | OUTLINE | 3.3 cm below the bottom at (0.23, -0.03, 0.04) · 3.3 cm above the top at (-0.23, 0.73, 0.04) |
| build/wall_shield__plank_root | OUTLINE | 3.3 cm below the bottom at (0.23, -0.03, 0.04) · 3.3 cm above the top at (-0.23, 0.73, 0.04) |
| build/weapon_rack__plank_mushroom | OUTLINE | 4.4 cm above the top at (0.04, 1.64, 0.06) |
| build/weapon_rack__plank_root | OUTLINE | 4.4 cm above the top at (-0.45, 1.64, 0.06) |
| build/window_diagonal__clay_brick | SHIMMER | charcoal_+1.60 on brick_b at (-1.02, 1.33, -0.96), 2261 cm² · charcoal_+1.60 on brick_a at (1.02, 1.33, 0.96), 1993 cm² · charcoal_+1.60 on brick_c at (0.96, 0.67, 1.02), 1188 cm² (+17 more) |
| build/window_diagonal__clay_brick | OUTLINE | 9.9 cm past the right side (x+) at (1.10, 1.22, 0.89) · 9.9 cm past the left side (x-) at (-1.10, 0.01, -0.89) · 9.9 cm past the front (z+) at (0.89, 1.22, 1.10) (+1 more) |
| build/window_diagonal__copper_ingot | SHIMMER | copper_dark on copper_c at (0.14, 1.40, 0.10), 1706 cm² · copper_dark on copper_c at (-0.10, 0.60, -0.14), 1706 cm² · copper_dark on copper_c at (0.33, 1.33, 0.37), 857 cm² (+1 more) |
| build/window_diagonal__copper_ingot | OUTLINE | 7.1 cm past the right side (x+) at (1.07, 1.02, 0.90) · 7.1 cm past the left side (x-) at (-1.07, 0.02, -0.90) · 7.1 cm past the front (z+) at (0.90, 1.02, 1.07) (+1 more) |
| build/window_diagonal__cut_stone | SHIMMER | charcoal_+1.60 on stone_c at (-1.02, 1.33, -0.96), 2587 cm² · charcoal_+1.60 on stone_c at (1.02, 1.33, 0.96), 2319 cm² · charcoal_+1.60 on stone_c at (1.02, 1.33, 0.96), 1782 cm² (+8 more) |
| build/window_diagonal__cut_stone | OUTLINE | 9.1 cm past the right side (x+) at (1.09, 0.03, 0.89) · 9.1 cm past the left side (x-) at (-1.09, 0.03, -0.89) · 9.1 cm past the front (z+) at (0.89, 0.03, 1.09) (+1 more) |
| build/window_diagonal__plank_root | SHIMMER | wood_a on wood_dark at (0.31, 1.40, 0.27), 423 cm² · wood_a on wood_dark at (-0.27, 0.60, -0.31), 423 cm² · wood_a on wood_dark at (0.26, 0.60, 0.22), 423 cm² (+5 more) |
| build/window_diagonal__plank_root | OUTLINE | 9.5 cm past the right side (x+) at (1.09, 0.14, 0.90) · 9.5 cm past the left side (x-) at (-1.09, 0.14, -0.90) · 9.5 cm past the front (z+) at (0.90, 0.14, 1.09) (+1 more) |
| build/window_wall__clay_brick | SHIMMER | brickochre_b on limestone_a at (0.13, 1.46, -0.16), 72 cm² · rooftile_c on limestone_a at (-0.18, 1.47, -0.16), 72 cm² · rooftile_c on brickochre_c at (-0.52, 1.10, -0.16), 48 cm² (+3 more) |
| build/window_wall__clay_brick | OUTLINE | 7.0 cm past the front (z+) at (-0.69, 0.51, 0.22) · 3.0 cm past the back (z-) at (-0.69, 0.51, -0.18) |
| build/window_wall__copper_ingot | SHIMMER | copper_dark on copper_c at (0.17, 1.40, -0.03), 1706 cm² · copper_dark on copper_c at (-0.17, 0.60, -0.03), 1706 cm² · copper_dark on copper_c at (0.50, 1.33, 0.03), 857 cm² (+1 more) |
| build/window_wall__copper_ingot | OUTLINE | 7.0 cm past the front (z+) at (-0.63, 0.53, 0.22) · 7.0 cm past the back (z-) at (-0.63, 0.53, -0.22) |
| build/window_wall__cut_stone | OUTLINE | 7.5 cm past the left side (x-) at (-1.08, 0.70, -0.11) · 6.0 cm past the front (z+) at (-0.63, 0.50, 0.21) · 3.3 cm past the back (z-) at (-0.97, 1.64, -0.18) (+1 more) |
| build/window_wall__plank_root | OUTLINE | 2.4 cm past the right side (x+) at (1.02, 1.72, -0.00) · 2.4 cm past the left side (x-) at (-1.02, 1.72, -0.00) · 1.6 cm below the bottom at (-0.95, -0.02, 0.07) (+1 more) |
| build/window_wide__clay_brick | SHIMMER | charcoal_+1.60 on brick_c at (-0.99, 1.33, 0.04), 1620 cm² · charcoal_+1.60 on brick_b at (0.99, 1.33, -0.04), 1620 cm² · charcoal_+1.60 on brick_c at (-0.26, 1.99, -0.04), 1422 cm² (+11 more) |
| build/window_wide__clay_brick | OUTLINE | 7.0 cm past the front (z+) at (-0.93, 0.53, 0.22) · 7.0 cm past the back (z-) at (-0.93, 0.53, -0.22) |
| build/window_wide__copper_ingot | SHIMMER | copper_dark on copper_c at (0.27, 1.50, -0.03), 2738 cm² · copper_dark on copper_c at (-0.27, 0.60, -0.03), 2738 cm² · copper_dark on copper_c at (0.80, 1.33, 0.03), 857 cm² (+1 more) |
| build/window_wide__copper_ingot | OUTLINE | 7.0 cm past the front (z+) at (-0.93, 0.53, 0.22) · 7.0 cm past the back (z-) at (-0.93, 0.53, -0.22) |
| build/window_wide__cut_stone | SHIMMER | charcoal_+1.60 on stone_c at (0.99, 1.33, -0.04), 1998 cm² · charcoal_+1.60 on stone_b at (-0.99, 1.33, 0.04), 1998 cm² · charcoal_+1.60 on stone_c at (0.99, 1.33, -0.04), 1782 cm² (+4 more) |
| build/window_wide__cut_stone | OUTLINE | 7.0 cm past the front (z+) at (-0.93, 0.53, 0.22) · 7.0 cm past the back (z-) at (-0.93, 0.53, -0.22) |
| build/window_wide__plank_root | SHIMMER | wood_dark on wood_c at (-0.31, 0.60, -0.07), 976 cm² · wood_dark on wood_b at (0.31, 0.60, 0.07), 976 cm² · wood_dark on wood_c at (-0.32, 1.50, 0.06), 844 cm² (+7 more) |
| build/window_wide__plank_root | OUTLINE | 7.0 cm past the front (z+) at (-0.93, 0.53, 0.22) · 7.0 cm past the back (z-) at (-0.93, 0.53, -0.22) |
| creatures/rock_beetle_spore | FLOAT | skin at (0.20, 0.13, 0.56), 11x22x19 cm, 4.3 cm from the rest |
| creatures/rock_snail_ember | FLOAT | skin at (-0.08, 0.32, 0.08), 19x25x19 cm, 11.1 cm from the rest |
| creatures/rock_snail_frost | FLOAT | skin at (-0.00, 0.31, 0.08), 35x25x20 cm, 2.6 cm from the rest · skin at (0.13, 0.20, 0.15), 1x1x0 cm, 1.9 cm from the rest |
| creatures/rock_snail_mossy | FLOAT | skin at (-0.08, 0.37, 0.07), 19x26x20 cm, 20.7 cm from the rest |
| creatures/rock_snail_spore | FLOAT | skin at (-0.08, 0.27, 0.07), 20x15x20 cm, 16.2 cm from the rest |
| decor/firefly_jar | FLOAT | c.001 at (0.06, 0.21, 0.06), 3x3x3 cm, 1.4 cm from the rest · c.001 at (0.05, 0.06, 0.00), 3x3x3 cm, 4.2 cm from the rest · c.001 at (-0.03, 0.12, -0.04), 2x3x3 cm, 4.4 cm from the rest (+3 more) |
| decor/firefly_jar | SHIMMER | c on rope_a at (0.03, 0.26, -0.07), 18 cm² |
| decor/firewood_rack | FLOAT | bark_c/wood_c at (0.08, 0.25, 0.00), 13x13x36 cm, 2.4 cm from the rest · bark_a/wood_c at (0.01, 0.64, 0.00), 13x13x36 cm, 1.8 cm from the rest · bark_b/wood_c at (-0.14, 0.38, 0.00), 13x13x36 cm, 1.9 cm from the rest (+12 more) |
| decor/glow_trellis | FLOAT | c/sprout at (-0.18, 1.18, 0.04), 10x9x5 cm, 3.6 cm from the rest · sprout at (0.23, 1.16, 0.03), 8x9x3 cm, 5.4 cm from the rest |
| decor/hearth_bed | FLOAT | brick_a at (0.21, 1.68, -0.90), 19x17x20 cm, 3.0 cm from the rest · brick_a at (-0.21, 1.68, -0.90), 19x17x20 cm, 3.0 cm from the rest · brick_c at (0.00, 1.70, -0.90), 16x12x20 cm, 3.2 cm from the rest |
| decor/hearth_bed | SHIMMER | brick_b on limestone_c at (0.58, 0.01, -1.00), 244 cm² · brick_b on limestone_b at (-0.58, 0.01, -1.00), 243 cm² · brick_a on brick_c at (-0.49, 1.56, -1.00), 72 cm² (+3 more) |
| decor/hearth_chair | SHIMMER | greenpaint_b on greenpaint_b at (0.15, 0.85, -0.23), 1423 cm² |
| decor/hearth_dresser | FLOAT | c at (-0.30, 1.04, -0.08), 21x22x6 cm, 1.3 cm from the rest · c at (0.30, 1.04, -0.08), 21x22x6 cm, 1.3 cm from the rest · c at (0.00, 1.04, -0.08), 21x22x6 cm, 1.3 cm from the rest |
| decor/hearth_fireplace | SHIMMER | c on charcoal_-0.20 at (0.06, 0.01, -0.10), 2484 cm² · brick_a on limestone_c at (-0.01, 0.97, 0.24), 150 cm² · brick_b on limestone_c at (-0.07, 0.97, -0.28), 100 cm² (+23 more) |
| decor/hearth_planter | SHIMMER | limestone_a on soil_a at (0.12, 0.40, -0.06), 1697 cm² |
| decor/hearth_rug | SHIMMER | c on rope_c at (0.22, 0.01, -0.56), 59 cm² · c on rope_a at (-0.63, 0.01, 0.15), 17 cm² · c on rope_a at (-0.62, 0.01, -0.15), 5 cm² (+2 more) |
| decor/keg | SHIMMER | wood_dark on wood_dark at (0.24, 0.04, 0.08), 48 cm² · wood_dark on wood_dark at (0.24, 0.02, -0.08), 48 cm² · wood_dark on wood_dark at (-0.36, 0.04, 0.08), 48 cm² (+1 more) |
| decor/mine_cart | SHIMMER | iron_dark on wood_c at (0.31, 0.18, -0.08), 221 cm² · iron_dark on wood_c at (-0.30, 0.18, -0.08), 221 cm² |
| decor/potted_fungus | SHIMMER | clay_a on soil_a at (0.08, 0.25, -0.16), 526 cm² |
| decor/rail_track | FLOAT | iron_a at (-0.22, 0.08, 0.00), 4x5x100 cm, 4.6 cm from the rest |
| decor/rune_shield | FLOAT | c at (0.00, 1.24, 0.08), 21x33x2 cm, 3.0 cm from the rest |
| decor/rune_shield | SHIMMER | c on c at (-0.00, 1.20, 0.09), 9 cm² · c on c at (0.04, 1.17, 0.09), 8 cm² |
| decor/shack_table | FLOAT | bark_b/wood_c at (0.00, 0.33, -0.00), 102x8x8 cm, 5.8 cm from the rest |
| decor/stone_bed | SHIMMER | limestone_b on copper_b at (-0.55, 0.29, 0.83), 39 cm² · stone_a on stone_a at (-0.53, 0.72, -0.83), 30 cm² · stone_c on stone_c at (-0.54, 0.89, -0.82), 25 cm² (+3 more) |
| decor/stone_chest | SHIMMER | charcoal_+0.40 on stone_a at (0.14, 0.02, -0.10), 567 cm² · charcoal_+0.40 on basalt_b at (0.14, 0.02, -0.10), 567 cm² · stone_a on stone_b at (-0.35, 0.45, -0.27), 24 cm² (+1 more) |
| decor/stone_table | SHIMMER | charcoal_+0.40 on stone_b at (0.17, 0.20, 0.10), 450 cm² |
| decor/stone_throne | SHIMMER | charcoal_+0.40 on stone_c at (0.10, 0.02, -0.08), 432 cm² |
| decor/stone_wall_shelf | SHIMMER | charcoal_+0.40 on stone_c at (0.14, 0.02, -0.10), 252 cm² · charcoal_+0.40 on brownrock_b at (-0.14, 0.90, -0.10), 126 cm² · charcoal_+0.40 on basalt_b at (0.14, 0.02, -0.10), 126 cm² (+4 more) |
| decor/stone_weapon_plaque | SHIMMER | charcoal_+0.40 on stone_a at (0.12, 1.00, -0.04), 83 cm² · charcoal_+0.40 on limestone_b at (0.12, 0.02, -0.07), 83 cm² · charcoal_+0.40 on limestone_b at (0.12, 0.02, -0.07), 83 cm² (+11 more) |
| decor/wall_torch | SHIMMER | wood_dark on iron_dark at (0.01, 0.56, -0.08), 275 cm² |
| items/amber_block | FLOAT | charcoal_+0.20 at (0.03, 0.13, 0.02), 6x4x4 cm, 5.9 cm from the rest · charcoal_+0.30 at (-0.05, 0.08, -0.03), 3x3x3 cm, 5.3 cm from the rest |
| items/boots_copper | SHIMMER | leather_dark on leather_dark at (0.00, 0.24, -0.08), 8 cm² · copper_b on copper_b at (0.01, 0.13, -0.09), 5 cm² |
| items/boots_leather | SHIMMER | leather_dark on leather_dark at (0.00, 0.24, -0.07), 12 cm² |
| items/boots_shell | SHIMMER | stone_c on stone_c at (0.01, 0.14, -0.09), 9 cm² · leather_dark on leather_dark at (0.00, 0.24, -0.07), 7 cm² |
| items/crossbow_stone | SHIMMER | iron_b on iron_b at (0.00, 0.65, 0.02), 8 cm² |
| items/drink_bellcap_juice | SHIMMER | cup(0.55, 0.7, 0.95) on clay_dark at (-0.02, 0.10, 0.06), 91 cm² |
| items/drink_deep_stout | SHIMMER | wood_b on drink(0.12, 0.08, 0.06) at (-0.00, 0.17, -0.05), 18 cm² |
| items/drink_glowcap_tea | SHIMMER | cup(0.3, 0.8, 0.75) on clay_dark at (-0.02, 0.10, 0.06), 91 cm² |
| items/drink_moss_ale | SHIMMER | wood_a on drink(0.5, 0.6, 0.25) at (-0.00, 0.17, -0.05), 18 cm² |
| items/fiber | SHIMMER | c on c at (-0.17, 0.07, -0.01), 10 cm² · c on c at (-0.11, 0.06, -0.01), 10 cm² |
| items/gem_bloomrot | FLOAT | silver_c at (-0.05, 0.10, 0.03), 2x7x2 cm, 1.3 cm from the rest · silver_b at (0.05, 0.10, -0.03), 2x7x2 cm, 1.4 cm from the rest |
| items/gem_cinder_wake | FLOAT | silver_a at (-0.05, 0.10, 0.03), 2x7x2 cm, 1.3 cm from the rest · silver_a at (0.05, 0.10, -0.03), 2x7x2 cm, 1.4 cm from the rest |
| items/gem_echoing_guard | FLOAT | silver_a at (-0.05, 0.10, 0.03), 2x7x2 cm, 1.3 cm from the rest · silver_a at (0.05, 0.10, -0.03), 2x7x2 cm, 1.4 cm from the rest |
| items/gem_hoarfrost_pulse | FLOAT | silver_a at (-0.05, 0.10, 0.03), 2x7x2 cm, 1.3 cm from the rest · silver_a at (0.05, 0.10, -0.03), 2x7x2 cm, 1.4 cm from the rest |
| items/gem_rootbound_heart | FLOAT | silver_b at (-0.05, 0.10, 0.03), 2x7x2 cm, 1.3 cm from the rest · silver_b at (0.05, 0.10, -0.03), 2x7x2 cm, 1.4 cm from the rest |
| items/gem_shiftstep | FLOAT | silver_b at (-0.05, 0.10, 0.03), 2x7x2 cm, 1.3 cm from the rest · silver_a at (0.05, 0.10, -0.03), 2x7x2 cm, 1.4 cm from the rest |
| items/leather | FLOAT | c at (0.06, 0.08, 0.10), 1x0x0 cm, 1.6 cm from the rest · c at (0.02, 0.08, 0.10), 1x0x0 cm, 1.2 cm from the rest · c at (0.11, 0.08, 0.10), 1x0x0 cm, 1.0 cm from the rest |
| items/mushroom_wood | SHIMMER | c.001 on mushwood_b at (0.02, 0.16, -0.00), 16 cm² · c.001 on mushwood_b at (-0.02, 0.16, -0.01), 6 cm² |
| items/plate_shell | SHIMMER | stone_b on stone_b at (0.06, 0.29, 0.11), 10 cm² · stone_b on stone_b at (0.05, 0.29, 0.11), 8 cm² · stone_b on stone_b at (0.03, 0.29, 0.11), 5 cm² (+1 more) |
| items/recipe_page | SHIMMER | sack_c on charcoal_+0.30 at (0.06, 0.01, 0.04), 5 cm² |
| items/root_tuber | FLOAT | sprout at (-0.08, 0.20, -0.02), 4x2x2 cm, 1.9 cm from the rest |
| items/shield_shell | SHIMMER | stone_c on stone_c at (-0.16, 0.45, 0.06), 14 cm² · stone_c on stone_c at (0.11, 0.29, 0.06), 14 cm² · stone_c on stone_c at (0.17, 0.45, 0.06), 13 cm² (+1 more) |
| items/spear_copper | SHIMMER | copper_dark on wood_b at (-0.00, 1.24, -0.02), 13 cm² |
| items/spear_silver | SHIMMER | silver_dark on wood_b at (-0.00, 1.24, -0.02), 16 cm² |
| items/spore_bomb | FLOAT | fire/iron_a/ropev_a/sporebomb_d at (0.00, 0.18, -0.03), 10x14x10 cm, 1.2 cm from the rest · sporebomb_d at (0.03, 0.12, 0.04), 3x2x3 cm, 1.0 cm from the rest · sporebomb_d at (0.05, 0.12, 0.00), 2x2x3 cm, 1.3 cm from the rest |
| items/sword_copper | SHIMMER | copper_b on copper_b at (-0.07, 0.22, 0.01), 8 cm² |
| items/waterskin_dirty | FLOAT | moss_-0.30 at (-0.07, 0.04, 0.07), 5x4x2 cm, 1.2 cm from the rest |
| items/waterskin_empty | FLOAT | leather_b at (-0.02, 0.06, -0.00), 20x6x11 cm, 1.6 cm from the rest |
| stations/bellows | SHIMMER | wood_dark on wood_dark at (0.14, 0.13, 0.05), 60 cm² · wood_dark on wood_dark at (0.14, 0.12, -0.05), 60 cm² · wood_dark on wood_dark at (-0.26, 0.13, 0.05), 60 cm² (+4 more) |
| stations/carpenters_vise | SHIMMER | iron_a on iron_c at (0.46, 0.86, -0.31), 7 cm² |
| stations/chest_copper | FLOAT | copper_b/copper_dark at (-0.50, 0.37, -0.00), 3x17x17 cm, 1.3 cm from the rest · copper_b/copper_dark at (0.50, 0.37, -0.00), 3x17x17 cm, 1.4 cm from the rest |
| stations/chest_copper | SHIMMER | copper_a on wood_c at (-0.41, 0.61, -0.07), 28 cm² |
| stations/chisel_rack | FLOAT | stone_b at (0.49, 0.06, -0.31), 11x9x9 cm, 6.2 cm from the rest |
| stations/chopping_block | FLOAT | wood_c at (0.17, 0.03, 0.31), 8x2x6 cm, 3.8 cm from the rest |
| stations/cooking_pot | FLOAT | bark_a/basalt_b/charcoal_+0.06/charcoal_+0.14/charcoal_+0.18/charcoal_+0.29/charcoal_-0.08/ember/stone_a/stone_b/stone_c/wood_c at (0.00, 0.09, 0.15), 77x15x78 cm, 12.1 cm from the rest |
| stations/copper_drip_basin | FLOAT | copper_a/copper_b/stone_a/water_light at (0.42, 0.24, 0.05), 29x47x23 cm, 2.7 cm from the rest · copper_dark at (-0.11, 0.96, 0.00), 18x2x18 cm, 4.4 cm from the rest · moss at (-0.31, 0.32, -0.36), 9x3x5 cm, 1.7 cm from the rest |
| stations/copper_drip_basin | SHIMMER | stone_b on charcoal_+0.40 at (-0.13, 0.01, 0.17), 118 cm² |
| stations/crate_ore | SHIMMER | wood_dark on wood_c at (-0.29, 0.04, -0.31), 19 cm² |
| stations/crystal_sconce | SHIMMER | stone_b on stone_a at (0.04, 0.44, -0.06), 612 cm² |
| stations/drip_bucket | SHIMMER | wood_dark on wood_c at (0.01, 0.09, -0.06), 188 cm² |
| stations/farm_plot | SHIMMER | stone_b on stone_b at (-0.57, 0.21, 0.49), 49 cm² · stone_b on stone_c at (-0.48, 0.21, -0.61), 29 cm² · stone_b on stone_c at (0.52, 0.01, 0.48), 10 cm² |
| stations/gem_bench | SHIMMER | stone_c on wood_dark at (-0.44, 1.02, 0.11), 276 cm² · stone_c on wood_dark at (-0.44, 0.90, -0.05), 62 cm² |
| stations/glow_lamp | FLOAT | gland at (-0.02, 1.05, -0.02), 10x12x10 cm, 2.9 cm from the rest |
| stations/glow_marker | SHIMMER | bannercloth_c on bannercloth_a at (0.09, 0.82, 0.05), 87 cm² |
| stations/grindstone | SHIMMER | wood_b on stone_c at (-0.15, 0.24, -0.13), 182 cm² |
| stations/kiln | FLOAT | wood_dark at (0.66, 0.17, -0.06), 12x12x50 cm, 1.6 cm from the rest |
| stations/kiln | SHIMMER | brick_a on brick_b at (0.25, 0.16, 0.37), 28 cm² · brick_a on brick_b at (-0.60, 0.16, -0.20), 28 cm² · brick_b on brick_c at (-0.27, 0.16, -0.52), 28 cm² (+5 more) |
| stations/rune_slab | FLOAT | charcoal_+0.30/glow_cyan at (0.28, 0.68, 0.15), 7x11x2 cm, 1.5 cm from the rest · charcoal_+0.30/glow_cyan at (0.28, 0.81, 0.15), 8x7x2 cm, 1.3 cm from the rest · charcoal_+0.30/glow_cyan at (0.28, 0.47, 0.15), 8x7x2 cm, 1.5 cm from the rest |
| stations/rune_slab | SHIMMER | charcoal_+0.30 on glow_cyan at (0.22, 0.97, 0.17), 82 cm² · charcoal_+0.30 on charcoal_+0.30 at (0.00, 0.84, 0.14), 78 cm² · charcoal_+0.30 on charcoal_+0.30 at (-0.01, 1.05, 0.14), 78 cm² (+4 more) |
| stations/smelter | SHIMMER | stone_b on stone_c at (-0.35, 0.25, -0.45), 25 cm² · stone_b on stone_b at (0.44, 0.25, -0.37), 19 cm² · stone_a on stone_dark at (0.23, 0.01, 0.57), 14 cm² |
| stations/tanning_rack | FLOAT | leather_b at (0.00, 0.78, 0.23), 87x83x21 cm, 2.4 cm from the rest |
| stations/tool_rack | SHIMMER | wood_dark on wood_dark at (-0.16, 0.74, -0.08), 205 cm² · wood_dark on wood_dark at (0.17, 0.68, -0.01), 193 cm² |
| stations/training_dummy | FLOAT | rope_a at (-0.00, 1.24, 0.00), 36x3x35 cm, 1.6 cm from the rest · charcoal_+0.10 at (-0.06, 1.50, 0.12), 7x4x2 cm, 1.0 cm from the rest |
| stations/training_dummy | SHIMMER | charcoal_+0.10 on charcoal_+0.10 at (0.10, 1.43, 0.11), 17 cm² · charcoal_+0.10 on charcoal_+0.10 at (0.10, 1.40, 0.11), 17 cm² · charcoal_+0.10 on charcoal_+0.10 at (0.10, 1.50, 0.11), 12 cm² |
| stations/twin_smelter | SHIMMER | stone_c on wood_b at (0.33, 0.31, -0.08), 54 cm² · stone_c on wood_b at (-0.32, 0.17, 0.00), 7 cm² |
| stations/workbench | FLOAT | wood_a/wood_b/wood_c at (0.00, 0.37, -0.09), 156x6x30 cm, 5.9 cm from the rest · moss at (-0.45, 0.87, 0.29), 19x6x3 cm, 4.1 cm from the rest |
| stations/workbench | SHIMMER | wood_b on wood_c at (-0.34, 0.35, 0.04), 664 cm² · wood_a on wood_b at (0.36, 0.35, 0.03), 656 cm² · wood_a on wood_c at (-0.05, 0.35, -0.22), 450 cm² (+4 more) |

**OK (255):** build/battlement_corner__cut_stone, build/bench__cut_stone, build/bench__plank_root, build/chair__plank_mushroom, build/chair__plank_root, build/column__clay_brick, build/column__copper_ingot, build/column__cut_stone, build/column__plank_root, build/column_base__ancient_brick, build/column_base__basalt, build/column_base__clay_brick, build/column_base__copper_ingot, build/column_base__cut_marble, build/column_base__cut_stone, build/column_base__plank_root, build/column_capital__ancient_brick, build/column_capital__basalt, build/column_capital__clay_brick, build/column_capital__copper_ingot, build/column_capital__cut_marble, build/column_capital__cut_stone, build/column_capital__plank_root, build/column_shaft__ancient_brick, build/column_shaft__basalt, build/column_shaft__clay_brick, build/column_shaft__copper_ingot, build/column_shaft__cut_marble, build/column_shaft__cut_stone, build/column_shaft__plank_root, build/floor_half__clay_brick, build/floor_half__cut_stone, build/floor_half__plank_root, build/half_wall__copper_ingot, build/ladder__clay_brick, build/ladder__copper_ingot, build/ladder__cut_stone, build/ladder__plank_root, build/pillar__clay_brick, build/shelf__plank_mushroom, build/shelf__plank_root, build/small_floor__clay_brick, build/small_floor__cut_stone, build/wall__copper_ingot, build/wall_narrow__copper_ingot, creatures/cave_bat_ember, creatures/cave_bat_frost, creatures/cave_bat_mossy, creatures/cave_bat_spore, creatures/rock_beetle_ember, creatures/rock_beetle_frost, creatures/rock_beetle_mossy, decor/banner_anvil, decor/banner_landscape, decor/bat_trophy, decor/beam_1m, decor/beam_2m, decor/beam_2m_26, decor/beam_2m_45, decor/brace_corner, decor/brazier, decor/candle_cluster, decor/chandelier, decor/cheese_shelf, decor/crate_stack, decor/crossed_pickaxes, decor/crystal_lamp_post, decor/fossil_plaque, decor/grain_sacks, decor/hanging_basket, decor/hanging_herbs, decor/hanging_lantern, decor/hearth_pot_rack, decor/hearth_table, decor/horn_plaque, decor/map_board, decor/mossy_bench, decor/mushroom_fountain, decor/mushroom_planter, decor/mushroom_stool, decor/ore_basket, decor/pole_1m, decor/pole_2m, decor/rope_fence, decor/shack_bed, decor/shack_bench, decor/shack_nightstand, decor/shack_peg_rack, decor/shack_rug, decor/shack_shelf, decor/shack_stool, decor/signpost, decor/stepping_stones, decor/stone_lantern, decor/stone_rug, decor/stone_stool, decor/tavern_table, decor/timber_stack, items/amberrock, items/ancient_brick, items/axe_2h_copper, items/axe_2h_silver, items/axe_2h_stone, items/axe_copper, items/axe_silver, items/axe_stone, items/basalt, items/bat_fang, items/beetle_meat, items/bellcap, items/blasting_pod, items/bloomheart_core, items/bolt_blight, items/bolt_ember, items/bolt_fang, items/bolt_glow, items/bolt_metal, items/bolt_rime, items/bolt_stone, items/bolt_thumper, items/brown_rock, items/bug_meat, items/bugbane_oil, items/build_hammer, items/cap_leather, items/chitin_plate, items/clay, items/clay_brick, items/coal, items/copper_ingot, items/copper_ore, items/critter_hide, items/critter_meat, items/crossbow_copper, items/crossbow_silver, items/crystal_amber, items/crystal_blue, items/crystal_green, items/crystal_red, items/crystal_violet, items/crystal_white, items/cut_marble, items/cut_stone, items/dirt, items/dish_beetle_roast, items/dish_bug_hotpot, items/dish_bug_stew, items/dish_chitin_crunch, items/dish_cooked_snail, items/dish_ember_skewer, items/dish_firecap_skewer, items/dish_glow_broth, items/dish_glowcap_skewer, items/dish_hearth_stew, items/dish_hollowcap_stew, items/dish_jungle_pie, items/dish_miners_pie, items/dish_roasted_bug, items/dish_seared_critter, items/dish_snail_stew, items/dish_spore_ward_stew, items/dish_stalk_steak, items/dish_truffle_risotto, items/dish_tuber_mash, items/drink_firecap_cordial, items/drink_spore_mead, items/ember_morel, items/firecap, items/gem_blight, items/gem_bulwark, items/gem_burrow, items/gem_ember, items/gem_jolt, items/gem_keen, items/gem_leech, items/gem_rime, items/gem_swift, items/gloam_scythe, items/glow_gland, items/glow_slime, items/glowcap, items/greaves_copper, items/greaves_shell, items/helm_copper, items/helm_shell, items/hollowcap, items/ironshell_plate, items/keeper_heartstone, items/lantern, items/lantern_back, items/lantern_lens, items/mace_2h_copper, items/mace_2h_silver, items/mace_2h_stone, items/mace_copper, items/mace_silver, items/mace_stone, items/mail_copper, items/marble, items/moss, items/mushroom_brick, items/mushroom_flesh, items/needle, items/pickaxe_copper, items/pickaxe_fang, items/pickaxe_silver, items/pickaxe_stone, items/plank_mushroom, items/plank_root, items/prospectors_lens, items/rootwood, items/rope, items/rune_cobalt, items/rune_crimson, items/rune_ochre, items/rune_verdant, items/rusty_scrap, items/satchel, items/scythe_blade, items/shell_piece, items/shield_copper, items/shield_silver, items/shield_stone, items/silver_ingot, items/silver_ore, items/sivix_silk, items/snail_meat, items/spear_stone, items/spitter_gill, items/spore_mask, items/spore_powder, items/spore_truffle, items/sporestone, items/sporestone_block, items/stone, items/sword_silver, items/sword_stone, items/trousers_leather, items/tunic_leather, items/venom_sac, items/war_horn, items/water_bucket, items/waterskin_clean, items/whetstone, items/wing_leather, items/wingskin, stations/anvil, stations/bed, stations/campfire, stations/chest_small, stations/chest_stone, stations/crate_ore_fill, stations/masonry_table, stations/rope_ladder, stations/stone_saw
