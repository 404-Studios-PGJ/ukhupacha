extends RefCounted
## Physics checks and real-input traversal probes; never attached to the level.
## MCP game_eval: load(path).new().run(current_scene).
## Call traverse with short waypoint batches below the bridge's 8s eval budget.
func traverse(level: Node2D, waypoints: Array) -> Dictionary:
	var player: CharacterBody2D = level.get_node("World/Player")
	var visited: Array[Dictionary] = []
	var failed: Array[String] = []
	Input.action_press("correr")
	for waypoint: Array in waypoints:
		var label: String = waypoint[0]
		var target: Vector2 = waypoint[1]
		for axis: int in [0, 1]:
			var offset: float = target[axis] - player.position[axis]
			if absf(offset) < 2.0:
				continue
			var direction: float = signf(offset)
			var action: String = ("derecha" if direction > 0 else "izquierda") if axis == 0 else ("abajo" if direction > 0 else "arriba")
			Input.action_press(action)
			var ticks: int = 0
			while (target[axis] - player.position[axis]) * direction > 2.0 and ticks < 240:
				await player.get_tree().physics_frame
				ticks += 1
			Input.action_release(action)
			await player.get_tree().physics_frame
			if ticks >= 240:
				failed.append(label)
				break
		visited.append({"name": label, "position": player.position})
		if not failed.is_empty():
			break
	Input.action_release("correr")
	return {"visited": visited, "failures": failed}

func run(level: Node2D) -> Dictionary:
	var player: CharacterBody2D = level.get_node("World/Player")
	var cases: Array = [
		["reception west wall", Vector2(64, 552), Vector2(-32, 0), true],
		["reception east wall", Vector2(448, 552), Vector2(32, 0), true],
		["reception north wall", Vector2(272, 448), Vector2(0, -64), true],
		["counter front", Vector2(180, 520), Vector2(0, -56), true],
		["counter east clearance", Vector2(280, 520), Vector2(0, -80), false],
		["waiting sofa", Vector2(96, 620), Vector2(0, -40), true],
		["displaced chair", Vector2(352, 210), Vector2(0, -40), true],
		["archive shelf", Vector2(96, 240), Vector2(0, -40), true],
		["archive opening", Vector2(272, 256), Vector2(-56, 0), false],
		["records opening", Vector2(656, 288), Vector2(0, 64), false],
		["security approach opening", Vector2(752, 192), Vector2(80, 0), false],
		["security closed boundary", Vector2(832, 128), Vector2(0, -64), true],
		["office circulation", Vector2(832, 200), Vector2(-432, 0), false],
		["transition lateral dodge clearance", Vector2(400, 352), Vector2(44, 0), false],
		["transition east jamb", Vector2(448, 352), Vector2(32, 0), true],
		["transition west jamb", Vector2(352, 352), Vector2(-32, 0), true],
		["records east wall", Vector2(736, 448), Vector2(32, 0), true],
		["record chair", Vector2(640, 480), Vector2(0, -40), true],
		["reception exit", Vector2(400, 448), Vector2(0, -160), false],
		["reception central circulation", Vector2(256, 688), Vector2(0, -152), false],
		["reception turn to connector", Vector2(256, 536), Vector2(144, 0), false],
		["office island desk", Vector2(560, 300), Vector2(0, -32), true],
	]
	var failures: Array[String] = []
	var results: Array[Dictionary] = []
	for item: Array in cases:
		var transform_at: Transform2D = player.global_transform
		transform_at.origin = item[1]
		var blocked: bool = player.test_move(transform_at, item[2])
		var passed: bool = blocked == item[3]
		results.append({"name": item[0], "passed": passed, "blocked": blocked})
		if not passed:
			failures.append(item[0])
	var floor_layer: TileMapLayer = level.get_node("Structure/Floor")
	var route: Array[Vector2] = [
		Vector2(256, 688), Vector2(256, 600), Vector2(256, 536),
		Vector2(400, 536), Vector2(400, 416), Vector2(400, 352),
		Vector2(400, 304), Vector2(400, 200), Vector2(752, 200),
		Vector2(784, 200), Vector2(832, 200), Vector2(832, 112),
		Vector2(240, 256), Vector2(656, 320), Vector2(656, 352)
	]
	for point: Vector2 in route:
		if floor_layer.get_cell_source_id(floor_layer.local_to_map(point)) < 0:
			failures.append("missing route floor at %s" % point)
	var world: Node2D = level.get_node("World")
	return {"checks": cases.size() + route.size(), "failures": failures,
		"physics": results, "player_count": world.find_children("*", "CharacterBody2D", true, false).size()}
