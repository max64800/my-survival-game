class_name ChestOpen
## Opening a chest (owner F345, Nov 18: no long wobble/spring/burst show; the lid swings open on its hinge and
## closes when you leave; short, the menu opens with it). Only looks, on the opener's own screen.
## Chests built with a lid part (kit.save(lid=...): the "lid" node, origin on the back hinge) swing it open;
## a box without a lid (the stone chest, crates) just gives a quick squash-and-pop.

const OPEN_TIME := 0.22   ## seconds for the lid to swing up
const CLOSE_TIME := 0.18
const OPEN_ANGLE := -1.75 ## radians about the hinge (about 100°, leaning back past upright)


## E at a chest: swing its lid open (or pop a lidless box). The menu opens at the same time.
static func open(body: Node3D) -> void:
	var lid := lid_of(body)
	if lid == null:
		_pop(body)
		return
	Sfx.play("clink", body.global_position + Vector3.UP * 0.5, -8.0, 0.75)  # (the latch)
	var t := _fresh_tween(lid)
	t.tween_property(lid, "rotation:x", OPEN_ANGLE * 1.06, OPEN_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(lid, "rotation:x", OPEN_ANGLE, 0.1).set_trans(Tween.TRANS_SINE)  # (a small bounce at the top)


## The menu closed (or you walked off): the lid drops shut with a little thump.
static func close(body: Node3D) -> void:
	var lid := lid_of(body)
	if lid == null or is_zero_approx(lid.rotation.x):
		return
	var t := _fresh_tween(lid)
	t.tween_property(lid, "rotation:x", 0.0, CLOSE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		if is_instance_valid(body):
			Sfx.play("close", body.global_position + Vector3.UP * 0.4, -8.0, 0.8))


## The chest's lid part, if its model has one.
static func lid_of(body: Node3D) -> Node3D:
	if body == null or not is_instance_valid(body):
		return null
	return body.find_child("lid", true, false) as Node3D


static func _fresh_tween(lid: Node3D) -> Tween:
	var old: Tween = lid.get_meta("lid_tween") if lid.has_meta("lid_tween") else null
	if old and old.is_valid():
		old.kill()
	var t := lid.create_tween()
	lid.set_meta("lid_tween", t)
	return t


## A box without a lid: a quick squash-and-pop of its model, so it never slows you down.
static func _pop(body: Node3D) -> void:
	var look := _look_of(body)
	if look == null:
		return
	var base: Vector3 = look.get_meta("chest_scale", look.scale)
	look.set_meta("chest_scale", base)
	var t := look.create_tween()
	t.tween_property(look, "scale", base * Vector3(1.08, 0.9, 1.08), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(look, "scale", base * Vector3(0.97, 1.06, 0.97), 0.07)
	t.tween_property(look, "scale", base, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The box's drawn model (not its collision or its name tag).
static func _look_of(body: Node3D) -> Node3D:
	for c in body.get_children():
		if c is Node3D and not (c is CollisionShape3D or c is Label3D) and String(c.name) != "Fill":
			return c
	return null
