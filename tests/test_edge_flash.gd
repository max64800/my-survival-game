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


func test_status_look_stays_on_through_a_hit() -> void:
	var f := ScreenEdgeFlash.new()
	f._ready()
	f.set_status("poison")
	f.flash_hit(50.0, 100.0)
	f._process(0.01)
	check(f._hit_strength > 0.0, "still mid-flash")
	f._process(f.HIT_FADE)
	f._process(0.01)
	check_eq(f._hit_strength, 0.0, "hit faded out")
	check_eq(f._status_kind, "poison", "status look still set (drawn under the hit rim, F799)")
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


func test_each_ailment_grows_in_its_own_look_and_melts_away() -> void:
	# F799 (owner, Nov 23): poison/burn/cold each get their own edge look; no popping in or out.
	var f := ScreenEdgeFlash.new()
	f._ready()
	f.set_status("poison", 2.0 / 3.0)
	f._process(0.01)
	f._process(ScreenEdgeFlash.FADE_IN * 0.5)
	check(f._fade > 0.3 and f._fade < 0.8, "poison grows in, doesn't pop")
	check_eq(f._mat.get_shader_parameter("status_mode"), 1, "poison draws the green creeping look")
	check_near(f._status_level, 2.0 / 3.0, 0.001, "2 of 3 stacks: stronger look")
	f._process(ScreenEdgeFlash.FADE_IN)
	check_near(f._fade, 1.0, 0.001, "fully grown in")
	f.set_status("chill", 0.4)  # switching: old look melts away first, then frost grows in
	f._process(ScreenEdgeFlash.FADE_OUT * 0.5)
	check_eq(f._mat.get_shader_parameter("status_mode"), 1, "still the poison look while it melts")
	f._process(ScreenEdgeFlash.FADE_OUT)
	f._process(0.01)
	f._process(0.01)
	check_eq(f._mat.get_shader_parameter("status_mode"), 3, "now the frost look")
	f.set_status("")
	for i in 40:
		f._process(0.05)
	check_eq(f._fade, 0.0, "gone after the ailment ends")
	f.set_status("nonsense")
	check_eq(f._status_kind, "", "unknown ailments show nothing")
	f.free()


func test_hud_picks_burn_then_poison_then_cold_with_stack_strength() -> void:
	var a := Ailments.new()
	var hud := Hud.new()
	hud._edge_flash = ScreenEdgeFlash.new()
	a.add("chill", 300)
	hud._update_edge_status(a)
	check_eq(hud._edge_flash._status_kind, "chill", "chilled: frost")
	check_near(hud._edge_flash._status_level, Hud.CHILL_EDGE_MAX, 0.001, "3 chill stacks = the most frost")
	a.add("chill", 200)  # 5th stack = frozen
	hud._update_edge_status(a)
	check_near(hud._edge_flash._status_level, Hud.CHILL_EDGE_MAX, 0.001, "frozen: frost stays the same as 3 stacks")
	a.add("poison", 100)
	hud._update_edge_status(a)
	check_eq(hud._edge_flash._status_kind, "poison", "poison shows over cold")
	a.add("burn", 100)
	hud._update_edge_status(a)
	check_eq(hud._edge_flash._status_kind, "burn", "burning wins")
	hud._edge_flash.free()
	hud.free()


func test_low_health_screen_grows_from_half_health_down() -> void:
	# F802 (owner, Nov 23): red edges + blood splats that get stronger the lower your health.
	var f := ScreenEdgeFlash.new()
	f._ready()
	f.set_health(0.8)
	check_eq(f._low_target, 0.0, "healthy: no red")
	f.set_health(0.3)
	check_near(f._low_target, 0.5, 0.01, "30% health: half strength")
	f._process(0.1)
	check(f._low > 0.0 and f._low < 0.5, "grows in, doesn't jump")
	f.set_health(0.05)
	check_near(f._low_target, 1.0, 0.001, "nearly dead: full strength")
	f.free()
