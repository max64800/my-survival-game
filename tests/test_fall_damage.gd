extends TestCase


## Drops `h` metres from a ledge with real gravity (frames of 1/60 s) and returns the drop the tracker reports.
func _drop(f: FallDamage, h: float, start_y := 10.0) -> float:
	var y := start_y
	var vy := 0.0
	var got := f.step(y, true, 0.0, 1.0 / 60.0)  # standing on the ledge
	while y > start_y - h:
		vy -= 9.8 / 60.0
		y = maxf(start_y - h, y + vy / 60.0)
		got += f.step(y, y <= start_y - h, vy, 1.0 / 60.0)
	return got


func test_fall_damage_numbers() -> void:
	check_eq(FallDamage.damage_for(3.0), 0.0, "3 m is free")
	check_eq(FallDamage.damage_for(4.0), 0.0, "4 m is free")
	check_eq(FallDamage.damage_for(6.0), 24.0, "6 m: 2 m too far x 12")
	check(FallDamage.damage_for(12.5) >= 100.0, "about 12 m kills (100 health)")


func test_falls_are_measured() -> void:
	check_near(_drop(FallDamage.new(), 3.0), 3.0, 0.1, "a 3 m drop is seen as 3 m")
	check_near(_drop(FallDamage.new(), 8.0), 8.0, 0.1, "an 8 m drop is seen as 8 m")


func test_ladders_jumps_and_teleports_dont_hurt() -> void:
	var f := FallDamage.new()
	f.step(10.0, true, 0.0, 0.016)
	var got := 0.0
	for i in 600:  # climbing down a 10 m ladder at 1 m/s
		got += f.step(10.0 - i / 60.0, false, -1.0, 1.0 / 60.0)
	got += f.step(0.0, true, 0.0, 0.016)
	check_eq(got, 0.0, "climbing down a ladder: no fall")
	f.step(20.0, true, 0.0, 0.016)
	check_eq(f.step(2.0, true, 0.0, 0.016), 0.0, "moved straight down (waking in a bed lower down): no fall")
	f.step(0.0, true, 0.0, 0.016)
	var y := 0.0
	var vy := 5.0
	got = 0.0
	for i in 120:  # a normal jump on flat ground
		vy -= 9.8 / 60.0
		y = maxf(0.0, y + vy / 60.0)
		got += f.step(y, y <= 0.0 and vy < 0.0, vy, 1.0 / 60.0)
	check_eq(got, 0.0, "a jump on flat ground: no fall")
