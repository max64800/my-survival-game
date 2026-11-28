extends TestCase
## F337 (Nov 26): the speed check reports more than the average: the median frame, the 1% low and the worst frame,
## and it can stand in a dungeon room.

const PerfCheck := preload("res://src/debug/perfcheck.gd")


func test_frame_stats_find_the_stutter() -> void:
	var t := PackedFloat32Array()
	for i in 99:
		t.append(10.0)  # 99 smooth frames (100 fps)...
	t.append(50.0)  # ...and one hitch
	var s: Dictionary = PerfCheck.frame_stats(t)
	check(is_equal_approx(s.median, 10.0), "median frame is the usual one (%s)" % s.median)
	check(is_equal_approx(s.worst, 50.0), "worst frame is the hitch (%s)" % s.worst)
	check(is_equal_approx(s.low1, 20.0), "1%% low = the slowest 1 in 100 frames as fps (%s)" % s.low1)
	check_eq(PerfCheck.frame_stats(PackedFloat32Array()).worst, 0.0, "no frames: no crash")


func test_dungeon_spot_is_inside_its_first_room() -> void:
	var map: Dictionary = DungeonMap.MAPS[0]
	var d := DungeonMap.place(map, Vector3(40, -30, 12), 1, 4.0)
	var spot := PerfCheck.dungeon_room_spot(d)
	var first := ""
	for s in map.spaces:
		if String(s[0]) != "entry":
			first = String(s[0])
			break
	check_eq(DungeonMap.space_at(d, spot), first, "the robot stands in the first room past the way in")
	check(DungeonMap.sdf(d, spot) > 0.0, "in the room's air, not in rock")


func test_lantern_shadow_is_two_sided_except_on_ultra() -> void:
	var was := GraphicsSettings.preset
	for p in ["potato", "low", "medium", "high"]:
		GraphicsSettings.preset = p
		check_eq(GraphicsSettings.lantern_shadow_mode(), OmniLight3D.SHADOW_DUAL_PARABOLOID, "%s: the cheap 2-sided shadow" % p)
	GraphicsSettings.preset = "ultra"
	check_eq(GraphicsSettings.lantern_shadow_mode(), OmniLight3D.SHADOW_CUBE, "ultra keeps the 6-sided cube")
	GraphicsSettings.preset = was
