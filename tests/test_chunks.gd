extends TestCase
## Breaking a block bursts into lots of bits that fly into the dwarf (feedback F13).


func test_burst_has_25_to_50_bits_that_fly_to_you_and_vanish() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var target := Node3D.new()
	root.add_child(target)
	target.global_position = Vector3(3, 0, 0)
	for k in 5:
		var s := ChunkSwarm.burst(root, Vector3.ZERO, Color.GRAY, target)
		var n := s.multimesh.instance_count
		check(n >= 25 and n <= 50, "a burst has 25-50 bits (%d)" % n)
		s.queue_free()
	var swarm := ChunkSwarm.burst(root, Vector3.ZERO, Color.GRAY, target, 30)
	var gone := false
	for i in 200:
		await tree.process_frame
		if not is_instance_valid(swarm):
			gone = true
			break
	check(gone, "all the bits reached the dwarf and the burst cleaned itself up")
	root.queue_free()


func test_bits_are_only_for_looks() -> void:
	# The burst has no physics bodies and gives no items: the normal drop does that.
	var root := Node3D.new()
	tree.root.add_child(root)
	var s := ChunkSwarm.burst(root, Vector3.ZERO, Color.GRAY, root, 40)
	check(s.get_child_count() == 0, "no extra nodes or bodies (one MultiMesh draws every bit)")
	var s2 := ChunkSwarm.burst(root, Vector3.ZERO, Color.GRAY, root, 40)
	check(s.multimesh.mesh == s2.multimesh.mesh, "same color reuses the same bit shape + material (fast)")
	var t := Time.get_ticks_usec()
	for i in 20:
		ChunkSwarm.burst(root, Vector3.ZERO, Color.GRAY, root, 50)
	var ms := (Time.get_ticks_usec() - t) / 20000.0
	check(ms < 3.0, "a burst is quick to start (%.2f ms)" % ms)
	root.queue_free()
