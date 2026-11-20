// Writes docs/design/zone1-dungeons/<nn>-<name>.md from the room maps (the D arrays) in the three dungeon pages.
// Usage: node gen_docs.js <repo dir>
const fs = require("fs"), path = require("path");
const here = __dirname, repo = process.argv[2], out = path.join(repo, "docs/design/zone1-dungeons");
fs.mkdirSync(out, { recursive: true });

function load(file) {
  const s = fs.readFileSync(path.join(here, file), "utf8");
  const js = s.slice(s.indexOf("<script>") + 8, s.indexOf("const COLW"));
  return new Function(js + "; return D;")();
}

const SIZES = {
  small: { mat: "root wood (Delver's Shack pieces, `plank_root`)", floor: 4, room: "6 x 6", hall: "10 x 8", end: "10 x 10", tunnel: "2 x 10", recipes: "Copper Axe, Crossbow, Spear, Copper-shod Boots", first: 2, time: "8-10 min" },
  medium: { mat: "Stonehold stone (`cut_stone`)", floor: 5, room: "8 x 8", hall: "12 x 12", end: "12 x 14", tunnel: "4 x 12", recipes: "Copper Helm, Copper Mail, Copper Greaves, Copper Shield, Copper Sword", first: 5, time: "12-15 min" },
  big: { mat: "Hearthbrick clay brick (`clay_brick`)", floor: 6, room: "8 x 8", hall: "16 x 12", end: "16 x 16", tunnel: "4 x 14", recipes: "Copper Mace, Two-handed Copper Axe, Two-handed Copper Mace", first: 10, time: "20-25 min" },
};

// Small dungeons were drawn with the outside creatures; inside they are the KayKit miners now (owner, Nov 20).
const SMALL_MOBS = { "snails": "tunnel rats", "bats": "tunnel rats", "beetles": "lost miners", "spiders": "tunnel rats (or spiders, owner to say)", "spider pack": "tunnel rat pack (or spiders, owner to say)", "pack + leader": "pack + leader (the Foreman)" };
const MOB_NAME = { "thralls": "Bone Thrall", "wardens": "Bone Warden", "rune callers": "Rune Caller", "creepers": "Grave Creeper", "tunnel rats": "Tunnel Rat", "lost miners": "Lost Miner", "tunnel rat pack": "Tunnel Rat pack", "Foreman + miners": "the Foreman with his Lost Miners (end fight)", "pack + leader": "a pack with its leader (end fight)", "pack + leader (the Foreman)": "the Foreman with his Lost Miners (end fight)" };

// size of a space on the 2 m grid (width x length in m, all even)
function size(r, z, d) {
  const n = r.name;
  if (r.k) {
    const lv = x => (d.rooms.find(q => q.n === x).l || 0);
    const joins = d.links.some(([a, b, k]) => !k && (a === r.n || b === r.n) && lv(a) !== lv(b));
    if (joins) return `${/Ladder|Shaft|Climb|Lift|Chute/.test(n) ? "2 x 2 shaft" : "4 x 8 stair"}, ${z.floor + 3} m between levels`;
    return z.tunnel;
  }
  if (/Bridge/.test(n)) return "4 x 14 (bridge), gap 10 deep";
  if (/Niche|Alcove|Vault|Stash|Hoard|Nook|Crib|Pantry|Loft$/.test(n)) return "4 x 4";
  if (r.tags.some(t => t.startsWith("page:"))) return z.end;
  if (/Hall|Gallery|Ground|Floor|Yard|Heart|Mint|Works|Dock|Row|Pits|Barrows?$|Ring/.test(n)) return z.hall;
  return z.room;
}

// which models a tag needs: [model, "exists"|"new", note]
function models(tag, sizeKey) {
  const [k, v] = tag.split(":");
  const stone = sizeKey !== "small";
  const M = [];
  const add = (m, st, note = "") => M.push([m, st, note]);
  if (/dart wall/.test(v)) add("trap_dart_wall", "exists");
  if (/dart plate/.test(v)) add("trap_dart_plate", "exists");
  if (/stalactites/.test(v)) add("trap_drip_thin / trap_drip_fat / trap_drip_cluster", "exists");
  if (/falling stones/.test(v)) add("trap_ceiling_stones", "new", "stone version of the drips: loose ceiling blocks");
  if (/crusher/.test(v) && !/great/.test(v)) stone ? add("trap_crusher_stone", "new", "stone/brick frame for the crusher") : add("trap_crusher", "exists");
  if (/great crusher/.test(v)) add("trap_crusher_great", "new", "bigger crusher that kills outright");
  if (/pit|shaft|chute/.test(v) && !/molten/.test(v) && k === "deadly") { add("trap_floor_break", "exists"); add("trap_spikes", "exists"); }
  if (/chasm/.test(v)) { stone ? add("bridge_stone_slab (+ cracked)", "new", "stone/brick bridge slabs that fall away") : add("bridge_plank / bridge_plank_broken / bridge_posts", "exists"); add("trap_spikes", "exists"); }
  if (/hidden boulder/.test(v)) add("cave boulder (Boulders.SHAPES)", "exists");
  if (/cracked wall/.test(v)) add("wall_cracked / wall_broken", "exists");
  if (/buried chest/.test(v)) add("floor_loose_stone + chest", "exists");
  if (/secret lever/.test(v)) add("lever", "exists");
  if (/loose panel|deep alcove/.test(v)) add("(building pieces only)", "exists");
  if (/healing shrine/.test(v)) add("healing shrine", "check", "Mossgate Hold has one: check the PC's kit");
  if (/recipe stand/.test(v)) add("recipe_stand + recipe_scroll", "exists");
  if (/key/.test(k)) add("tr_key_copper / tr_key_iron (recoloured per key)", "exists", "key items are new code");
  if (k === "lock") add(stone ? "door_locked_round (stone/brick, with a keyhole)" : "gate_round", stone ? "new" : "exists");
  if (/carts/.test(v)) { add(/ore/.test(v) ? "ore_cart (forge mine cart)" : "mine_cart", /ore/.test(v) ? "new" : "exists"); add("rail_lanes_3 + cart_stop + cart_release", "new", "3 rails side by side, carts in a pattern; ragdoll on hit"); }
  if (/push wall/.test(v)) add("trap_push_wall (" + (stone ? "stone/brick" : "wood") + ") + floor scrape", "new");
  if (/swinging boulder/.test(v)) add("trap_swing_boulder (+ beam/arch hook)", "new", "ragdoll on hit");
  if (/swinging anvil/.test(v)) add("trap_swing_anvil", "new", "ragdoll on hit");
  if (/tipping brazier/.test(v)) add("trap_brazier_tip + ember_floor", "new", "shoot the chain to tip it early");
  if (/pendulum blade/.test(v)) add("trap_pendulum_blade + ceiling slot", "new");
  if (/bell pendulum/.test(v)) add("trap_bell_pendulum", "new");
  if (/spear wall/.test(v)) add("trap_spear_wall (" + (stone ? "iron spears" : "wooden stakes") + ")", "new");
  if (/tripwire/.test(v)) add("trap_tripwire_crossbow (crossbow + wire + peg)", "new");
  if (/bear jaw/.test(v)) add("trap_bear_jaw (open + shut)", "new");
  if (/portcullis/.test(v)) add("portcullis (stone/brick frame)", "new");
  if (/collapsing stairs/.test(v)) { add("stairs_collapsing (faint off-colour half)", "new"); add("trap_spikes", "exists"); }
  if (/spiked flail/.test(v)) add("trap_flail (post + chain + spiked ball)", "new", "ragdoll on hit");
  if (/trapped chest/.test(v)) { add("floor_spike_holes", "new", "shoot the chest first: the spikes fire and pull back"); add("trap_spikes", "exists"); }
  if (/swinging crucible/.test(v)) add("trap_swing_crucible", "new");
  if (/rolling (boulder|anvil)/.test(v)) add(/anvil/.test(v) ? "trap_roll_anvil + ramp groove" : "trap_roll_boulder + ramp groove + side alcoves", "new");
  if (/molten/.test(v)) add(/moulds/.test(v) ? "mould_lid (+ cracked) over molten metal" : "molten_channel (stone channel + glowing metal surface)", "new", "never spills: works like spikes");
  if (/great press/.test(v)) add("trap_press", "new");
  if (/chasm drop/.test(v)) add("bridge_chain_section (drops and rises)", "new");
  if (k === "out") {
    if (/lift/.test(v)) add("lift platform + winch", "new");
    else if (/slide/.test(v)) add(stone ? "stone slide (building pieces)" : "rope slide", stone ? "exists" : "new");
    else if (/climb/.test(v)) add("rope_ladder", "exists");
    else if (/gate/.test(v)) add("gate_round + lever", "exists");
    else add("lever + hidden door (wall piece)", "exists");
  }
  return M;
}

const LOOT = {
  small: ["Side chest: 2-5 Rusty Scrap, 3-8 gold, 1-3 rope or 2 Crystal Torches, 30% a cooked food",
    "Hidden chest (vault, buried, niche): 8-15 gold, 1-2 Copper Ingots, 20% a rune, 3% a gem",
    "Recipe stand: this dungeon's page (always the same recipe), 10-20 gold"],
  medium: ["Side chest: 3-6 Rusty Scrap, 5-10 gold, 1-3 Bandages or 5 Stone Bolts, 30% a cooked food",
    "Hidden chest: 12-20 gold, 2-3 Copper Ingots, 30% a rune, 5% a gem",
    "Mini boss: drops the key, 5-10 gold",
    "Recipe stand + big chest: this dungeon's page, 20-30 gold, 25% an Old Blueprint the group doesn't know yet, 8% a gem"],
  big: ["Side chest: 4-8 Rusty Scrap, 8-15 gold, 2-4 Bandages or 8 Metal Bolts, 40% a cooked food",
    "Hidden chest: 15-25 gold, 3-5 Copper Ingots, 40% a rune, 8% a gem",
    "Mini boss: drops its key, 10-15 gold",
    "Recipe stand + big chest: this dungeon's page, 30-50 gold, 35% an Old Blueprint the group doesn't know yet, 12% a gem"],
};

function doc(d, sizeKey, num) {
  const z = SIZES[sizeKey];
  const rooms = d.rooms.map(r => ({ ...r, tags: r.tags.map(t => {
    const [k, v] = t.split(":");
    return k === "mob" && sizeKey === "small" ? `mob:${SMALL_MOBS[v] || v}` : t;
  }) }));
  const tagText = t => { const [k, v] = t.split(":"); return k === "deadly" ? `**deadly: ${v}**` : `${k}: ${v}`; };
  let s = `# #${num} ${d.name}\n\n`;
  s += `*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*\n\n`;
  s += `${d.idea}\n\n`;
  s += `| | |\n|---|---|\n| Size | ${sizeKey}, ${rooms.length} spaces, ${d.layers.length} level(s), ${z.time} |\n| Built from | ${z.mat}, inside old dwarf stone (can't be dug) |\n| Floor to ceiling | ${z.floor} m in rooms, more in tall halls |\n| Teaches one of | ${z.recipes} (shuffled per world) |\n| Way out | ${d.outNote} |\n\n`;
  s += `## Rooms (sizes in metres on the 2 m grid, width x length)\n\n| # | Space | Level | Size | What's there | Has |\n|---|---|---|---|---|---|\n`;
  for (const r of rooms) s += `| ${r.n} | ${r.name}${r.k ? " (corridor)" : ""} | ${d.layers[r.l || 0]} | ${size(r, z, d)} | ${r.what} | ${r.tags.map(tagText).join("; ")} |\n`;
  s += `\nPaths: ${d.links.map(([a, b, k]) => k ? `${a} → ${b} (way out)` : `${a}-${b}`).join(", ")}.\n\n`;
  const mobs = {};
  for (const r of rooms) for (const t of r.tags) if (t.startsWith("mob:") || t.startsWith("boss:")) { const v = t.split(":")[1]; mobs[v] = (mobs[v] || 0) + 1; }
  s += `## Creatures\n\n` + Object.entries(mobs).map(([k, n]) => `- ${MOB_NAME[k] || k}: ${n} room(s)`).join("\n") + "\n\n";
  s += `## Loot\n\n` + LOOT[sizeKey].map(x => "- " + x).join("\n") + `\n- Everything refills 1 hour of play after it was taken (DungeonLoot).\n\n`;
  const seen = new Map();
  for (const r of rooms) for (const t of r.tags) for (const [m, st, note] of models(t, sizeKey)) if (!seen.has(m)) seen.set(m, [st, note]);
  s += `## 3D models it needs\n\n| Model | Status | Note |\n|---|---|---|\n| ${z.mat.split(" (")[0]} building pieces (walls, floors, round doorways, stairs, pillars, beams, railings, ladders) | exists | |\n| dungeon_entrance${sizeKey === "small" ? "" : " (stone/brick version)"} | ${sizeKey === "small" ? "exists" : "new"} | the round door in the cave wall |\n`;
  for (const [m, [st, note]] of seen) s += `| ${m} | ${st} | ${note} |\n`;
  s += `| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |\n`;
  return s;
}

const all = [];
for (const [file, sizeKey] of [["small-dungeons.html", "small"], ["medium-dungeons.html", "medium"], ["big-dungeons.html", "big"]]) {
  load(file).forEach((d, i) => {
    const num = SIZES[sizeKey].first + i;
    const name = `${String(num).padStart(2, "0")}-${d.name.toLowerCase().replace(/[^a-z]+/g, "-").replace(/^-|-$/g, "")}.md`;
    fs.writeFileSync(path.join(out, name), doc(d, sizeKey, num));
    all.push([num, d.name, sizeKey, d.rooms.length, name]);
  });
}
console.log(all.map(a => a.join(" | ")).join("\n"));
