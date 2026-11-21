extends TestCase
## F579: the Build Hammer teaches one step at a time and remembers what you learned (own file, not the save).

const PATH := "user://claude_test_lessons_check.cfg"


func test_one_lesson_at_a_time_then_a_short_line() -> void:
	DirAccess.remove_absolute(PATH)
	var l := BuildLessons.new(PATH)
	check(l.text().contains("NEXT:  Press B"), "starts with: press B to choose a piece")
	check(not l.text().contains("Q or E"), "later lessons stay hidden (one thing at a time)")
	check(l.mark("choose"), "choosing a piece ticks the first lesson")
	check(not l.mark("choose"), "doing it again is not new")
	check(l.text().contains("✓ Press B"), "the done lesson shows a tick")
	check(l.text().contains("NEXT:  Left click"), "next: left click to place")
	l.mark("turn")  # done out of order: still counts
	l.mark("place")
	check(l.text().contains("NEXT:  Hold Shift"), "skips lessons already done")
	l.mark("lift")
	l.mark("pickup")
	check(l.all_done(), "all five learned")
	check_eq(l.text(), BuildLessons.SHORT_KEYS, "then only the short one-line key list")
	check_eq(l.text().count("\n"), 0, "the key list is one line")
	DirAccess.remove_absolute(PATH)


func test_progress_is_remembered_in_its_own_file() -> void:
	DirAccess.remove_absolute(PATH)
	var a := BuildLessons.new(PATH)
	a.mark("choose")
	a.mark("place")
	var b := BuildLessons.new(PATH)
	check_eq(b.count_done(), 2, "a new world (new BuildLessons) remembers the 2 lessons")
	check_eq(b.next_id(), "turn", "and carries on with turning")
	DirAccess.remove_absolute(PATH)


func test_auto_checks_never_touch_the_owners_lessons() -> void:
	check_eq(BuildLessons.new().path, "user://claude_test_build_lessons.cfg", "test runs use their own lessons file")


func test_build_mode_ticks_lessons_as_you_build() -> void:
	var bm := BuildMode.new()
	bm.lessons = BuildLessons.new(PATH)
	bm.lessons.done.clear()
	tree.root.add_child(bm)
	bm.choose("wall", "plank_root")
	check(bm.lessons.done.has("choose"), "picking a piece in the B menu ticks 'choose'")
	bm.turn(1)
	check(bm.lessons.done.has("turn"), "turning ticks 'turn'")
	bm.queue_free()
	DirAccess.remove_absolute(PATH)
