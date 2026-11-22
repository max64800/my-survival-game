extends TestCase
## F695 (owner, Nov 22): the screen edges flash red the moment you're hit, and glow green/orange/blue
## while poisoned/burning/chilled. Checks the signal, the fade, and that a hit wins over a status glow.


func test_a_real_hit_emits_damaged_but_an_ailment_tick_does_not() -> void:
	var v := Vitals.new()
	var seen := []
	v.damaged.connect(func(amount): seen.append(amount))
	v.take_damage(30.0)
	check_eq(seen.size(), 1, "one real hit: one signal")
	check_near(seen[0], 30.0, 0.01, "carries the amount")
	v.ailments.add("poison", 100)
	seen.clear()
	for i in 20:
		v.tick(0.1)
	check_eq(seen.size(), 0, "poison ticking doesn't spam the flash (F695)")


func test_god_mode_and_zero_damage_dont_flash() -> void:
	var v := Vitals.new()
	v.god = true
	var seen := []
	v.damaged.connect(func(amount): seen.append(amount))
	v.take_damage(9999.0)
	check_eq(seen.size(), 0, "god mode: no hit, no flash")


func test_small_hits_skip_the_edge_and_big_ones_flash_faintly() -> void:
	# Owner, Nov 22: the old flash was "too much": now only big hits, thin and faint (HIT_MAX).
	var f := ScreenEdgeFlash.new()
	f._ready()
	f.flash_hit(5.0, 100.0)
	check_eq(f._hit_strength, 0.0, "a small hit (5% of health) doesn't touch the screen edge")
	f.flash_hit(10.0, 100.0)
	check_near(f._hit_strength, ScreenEdgeFlash.HIT_MIN, 0.01, "a 10% hit flashes faintly")
	f.flash_hit(80.0, 100.0)
	check_near(f._hit_strength, ScreenEdgeFlash.HIT_MAX, 0.01, "a huge hit caps at HIT_MAX")
	check(ScreenEdgeFlash.HIT_MAX <= 0.35, "never a strong flash")
	f._process(ScreenEdgeFlash.HIT_FADE)
	check_near(f._hit_strength, 0.0, 0.001, "fully faded after HIT_FADE seconds")
	f.free()


func test_a_fresh_hit_doesnt_get_weaker_than_the_fading_one() -> void:
	var f := ScreenEdgeFlash.new()
	f._ready()
	f.flash_hit(50.0, 100.0)
	f._process(f.HIT_FADE * 0.25)
	var mid := f._hit_strength
	f.flash_hit(11.0, 100.0)  # a smaller big hit while the strong one is still fading
	check_eq(f._hit_strength, mid, "doesn't dim an already-brighter flash")
	f.free()


func test_status_glow_shows_only_once_the_hit_flash_is_gone() -> void:
	var f := ScreenEdgeFlash.new()
	f._ready()
	f.set_status("poison")
	f.flash_hit(50.0, 100.0)
	f._process(0.01)
	check(f._hit_strength > 0.0, "still mid-flash")
	f._process(f.HIT_FADE)
	f._process(0.01)
	check_eq(f._hit_strength, 0.0, "hit faded out")
	check_eq(f._status_kind, "poison", "status glow still set, now visible")
	f.free()


func test_getting_hurt_bumps_the_camera_a_little_and_flashes_the_dwarf() -> void:
	# F695 (owner Nov 22): small bump for a small hit, bigger for a big one, never more than HURT_SHAKE_MAX.
	var d := Dwarf.new()
	d.got_hurt(1.0, 100.0)
	check_near(d._shake, Dwarf.HURT_SHAKE_MIN, 0.02, "a scratch: a tiny bump")
	d._shake = 0.0
	d.got_hurt(90.0, 100.0)
	check_near(d._shake, Dwarf.HURT_SHAKE_MAX, 0.001, "a huge hit: the biggest hurt bump")
	d.free()
	var m := DwarfModel.new()
	m.hurt_flash()  # not in the tree yet: must not crash
	m.free()
