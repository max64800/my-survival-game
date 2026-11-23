## Nov 23: red screen earlier + Arena "screen looks" tools

**Owner notes:** the red edges and blood only showed around 33% health (wanted from about 50%). Dying in the Arena sent the dwarf to the first dungeon. Asked for F10 tools: god mode, an HP slider, and status looks that don't hurt.

**Fixes:** the low-health strength now follows a square-root curve, so it is clearly visible just under half health (46% shows it in a test picture). Arena sets the dwarf's bed to the arena spot, so dying wakes you up there. New F10 section: God mode button, HP slider with "Hold my health at the slider" (turns god mode off, since god mode would refill you), Poison/Burn/Chill/No-look buttons (`hud.edge_fake`, looks only), Small/Big hit buttons (look only).

**Not done:** monsters hitting the dwarf still has no spark burst (part of F717).
