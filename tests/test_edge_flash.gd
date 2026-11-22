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


func test_flash_strength_scales_then_fades_to_nothing() -> void:
	var f := ScreenEdgeFlash.new()
	f._ready()
	f.flash_hit(0.0)
	check_near(f._hit_strength, 0.35, 0.01, "even a 0-damage hit flashes a little")
	var f2 := ScreenEdgeFlash.new()
	f2._ready()
	f2.flash_hit(50.0)
	check_eq(f2._hit_strength, 1.0, "a big hit caps at full strength")
	f2._process(ScreenEdgeFlash.HIT_FADE)
	check_eq(f2._hit_strength, 0.0, "fully faded after HIT_FADE seconds")
	f.free()
	f2.free()


func test_a_fresh_hit_doesnt_get_weaker_than_the_fading_one() -> void:
	var f := ScreenEdgeFlash.new()
	f._ready()
	f.flash_hit(50.0)
	f._process(f.HIT_FADE * 0.5)
	var mid := f._hit_strength
	f.flash_hit(0.0)  # a tiny new hit while the big one is still fading
	check_eq(f._hit_strength, mid, "doesn't dim an already-brighter flash")
	f.free()


func test_status_glow_shows_only_once_the_hit_flash_is_gone() -> void:
	var f := ScreenEdgeFlash.new()
	f._ready()
	f.set_status("poison")
	f.flash_hit(50.0)
	f._process(0.01)
	check(f._hit_strength > 0.0, "still mid-flash")
	f._process(f.HIT_FADE)
	f._process(0.01)
	check_eq(f._hit_strength, 0.0, "hit faded out")
	check_eq(f._status_kind, "poison", "status glow still set, now visible")
	f.free()
