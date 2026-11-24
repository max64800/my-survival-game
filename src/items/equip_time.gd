class_name EquipTime
## How long putting something on takes (F826, owner Nov 23: "like Valheim"). While the ring fills you walk very
## slowly, a hit stops it, and the item can't be used yet. Taking armour off takes a ring too (F828); the rest is instant.
## The ring itself: GameAuthority.ask_equip / tick_equip / cancel_equip; the picture: Hud._show_equip_ring.

const ARMOUR_SECONDS := 1.5  ## head, chest, legs, feet
const OTHER_SECONDS := 0.5  ## weapons, tools, shields, lanterns, backpacks
const WALK_MULT := 0.3  ## "move very very slowly" (owner)


static func seconds_for(id: String) -> float:
	return ARMOUR_SECONDS if Items.kind(id) == "wear" else OTHER_SECONDS


## Taking it off: armour takes the same ring (owner F828); weapons, tools, shields, lanterns, backpacks are instant.
static func seconds_off(id: String) -> float:
	return ARMOUR_SECONDS if Items.kind(id) == "wear" else 0.0


## 0..1 how full the ring is (1 = done). An empty job = 0.
static func progress(job: Dictionary) -> float:
	if job.is_empty() or float(job.get("total", 0.0)) <= 0.0:
		return 0.0
	return clampf(1.0 - float(job.left) / float(job.total), 0.0, 1.0)
