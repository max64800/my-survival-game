class_name FirstCards
extends RefCounted
## F870 (owner, Nov 25: "teach with pictures, not words"): the first time you meet something new (your lantern, a glow
## crystal, copper, your first workbench, poison, hunger...) a picture card pops up on the left: its picture + one line.
## Each card shows once. Every card you've seen is kept in the Notes tab of the skills window (J).
## Setting "Hints and cards" (on by default) turns the pop-ups off; the Notes still fill up.
## What you've seen lives in its own little file on this computer (not in the world save), so a new world doesn't
## show the same cards again (like the old hammer lessons did).

const SETTINGS := "user://settings.cfg"  ## the "Hints and cards" switch (same file as the sound settings)

## id -> [name, one line, picture]. The picture is an item id (its bag icon) or a res:// path.
## Most cards are about a thing that lands in your bag the first time (`items` says which ids count).
const CARDS := {
	"lantern": ["Lantern", "Lights your way. R refills it with fuel, L puts it away", "lantern"],
	"stone": ["Stone", "Stone + rootwood make your first pickaxe (Tab)", "stone"],
	"rootwood": ["Rootwood", "For planks, tools and a campfire. It burns in the lantern too", "rootwood"],
	"crystal": ["Glow crystal", "Lantern fuel: press R to refill", "crystal_white"],
	"pickaxe": ["Pickaxe", "Hold left click on rock and soft walls to dig", "pickaxe_stone"],
	"clay": ["Clay", "For a smelter, a kiln and bricks", "clay"],
	"copper_ore": ["Copper ore", "Melt it into copper in a smelter", "copper_ore"],
	"tin_ore": ["Tin ore", "Smelt it into Tin Bars; 3 copper + 1 tin at the anvil make bronze", "tin_ore"],
	"workbench": ["Workbench", "Place it, then E to make more things", "workbench"],
	"smelter": ["Smelter", "Place it, then put in ore and fuel to melt metal", "smelter"],
	"campfire": ["Campfire", "Place it, then E to cook", "campfire"],
	"blueprint": ["Blueprint", "V shows your blueprints (with the hammer)", "blueprint_page"],
	"poison": ["Poison", "It hurts you a little at a time", "res://assets/icons/status/poison.png"],
	"burn": ["Burning", "Fire hurts until it goes out", "res://assets/icons/status/burn.png"],
	"chill": ["Cold", "Cold slows you down. Too cold and you freeze", "res://assets/icons/status/chill.png"],
	"frozen": ["Frozen", "You can't move for a moment", "res://assets/icons/status/frozen.png"],
	"hungry": ["Hungry", "Eat: right click food in your hotbar", "res://assets/icons/hud/hunger.png"],
	"thirsty": ["Thirsty", "Find water and drink", "res://assets/icons/hud/thirst.png"],
}
## Which bag items show which card (the first one found).
const ITEMS := {
	"lantern": ["lantern", "lantern_hip", "lantern_back", "lantern_lens"],
	"stone": ["stone"], "rootwood": ["rootwood"], "clay": ["clay"],
	"crystal": ["crystal_white", "crystal_amber", "crystal_violet", "crystal_blue", "crystal_green", "crystal_red"],
	"pickaxe": ["pickaxe_stone", "pickaxe_copper", "pickaxe_bronze", "pickaxe_silver", "pickaxe_fang"],
	"copper_ore": ["copper_ore"], "tin_ore": ["tin_ore"],
	"workbench": ["workbench"], "smelter": ["smelter"], "campfire": ["campfire"],
	"blueprint": ["blueprint_page"],
}
const LOW := 30.0  ## hunger / thirst below this = the "Hungry" / "Thirsty" card

static var hints_on := true  ## settings: "Hints and cards"

var path := "user://first_cards.cfg"
var seen: Array[String] = []  ## card ids, in the order you met them


func _init(p_path: String = "") -> void:
	if p_path != "":
		path = p_path
	elif ClaudeTest.active() or _in_auto_checks():  # Claude's tests never use up the owner's cards
		path = "user://claude_test_first_cards.cfg"
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		for id in cfg.get_value("cards", "seen", []):
			if CARDS.has(id) and not id in seen:
				seen.append(id)


static func _in_auto_checks() -> bool:
	var loop := Engine.get_main_loop()
	return loop != null and loop.get_script() != null and str(loop.get_script().resource_path).begins_with("res://tests/")


static func load_setting(p: String = SETTINGS) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(p) == OK:
		hints_on = bool(cfg.get_value("hints", "cards", true))


static func set_hints(on: bool, p: String = SETTINGS) -> void:
	hints_on = on
	var cfg := ConfigFile.new()
	cfg.load(p)  # keep the other settings in the file
	cfg.set_value("hints", "cards", on)
	cfg.save(p)


## A card's picture.
static func picture(id: String) -> Texture2D:
	var pic: String = CARDS[id][2]
	if pic.begins_with("res://"):
		return load(pic) if ResourceLoader.exists(pic) else null
	return Items.icon(pic)


## Marks a card seen. True the first time (= show it now).
func meet(id: String) -> bool:
	if not CARDS.has(id) or id in seen:
		return false
	seen.append(id)
	var cfg := ConfigFile.new()
	cfg.set_value("cards", "seen", seen)
	cfg.save(path)
	return true


## Looks at the player's bag, sicknesses, hunger and thirst; returns the cards met for the first time just now.
func check(ps: GameAuthority.PlayerState) -> Array[String]:
	var out: Array[String] = []
	for id in ITEMS:
		if id in seen:
			continue
		for item in ITEMS[id]:
			if ps.inventory.count_of(item) > 0:  # (the bag, the hotbar and what you wear)
				if meet(id):
					out.append(id)
				break
	var v := ps.vitals
	for kind in ["poison", "burn", "chill", "frozen"]:
		if v.ailments.has(kind) and meet(kind):
			out.append(kind)
	if v.hunger < LOW and meet("hungry"):
		out.append("hungry")
	if v.thirst < LOW and meet("thirsty"):
		out.append("thirsty")
	return out

