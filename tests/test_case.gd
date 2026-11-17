class_name TestCase
extends RefCounted
## Base for auto-checks. Every method starting with "test_" is one check.

var failures: Array[String] = []
var tree: SceneTree


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func check_eq(a: Variant, b: Variant, msg: String) -> void:
	if a != b:
		failures.append("%s (got %s, expected %s)" % [msg, str(a), str(b)])


func check_near(a: float, b: float, tol: float, msg: String) -> void:
	if absf(a - b) > tol:
		failures.append("%s (got %f, expected %f ± %f)" % [msg, a, b, tol])


## Waits a number of frames (for tests that need the game running).
func frames(n: int) -> void:
	for i in n:
		await tree.process_frame


## The first hotbar slot holding something other than a pickaxe: where a test's freshly added item
## lands, now that the starting pickaxe sits in the hotbar (owner F243). -1 = none.
func first_item_slot(p: GameAuthority.PlayerState) -> int:
	for i in Inventory.HOTBAR_SIZE:
		var id: String = p.inventory.get_slot(i).get("id", "")
		if id != "" and Items.kind(id) != "pickaxe":
			return i
	return -1
