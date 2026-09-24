class_name InteractionSystem
extends Node
## Una instancia por contenedor activo. No modifica Player.

var focused: Interactable


func _physics_process(_delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if not player_can_interact(player):
		_set_focus(null)
		return
	_set_focus(find_nearest(player))
	if Input.is_action_just_pressed(&"interactuar") and is_instance_valid(focused):
		focused.interact(player)


func player_can_interact(player: Node) -> bool:
	if not is_instance_valid(player) or get_tree().paused:
		return false
	if player.has_method("is_input_enabled"):
		return bool(player.call("is_input_enabled"))
	for property: Dictionary in player.get_property_list():
		if property["name"] == &"input_enabled":
			return bool(player.get("input_enabled"))
	return false


func find_nearest(player: Node2D) -> Interactable:
	var nearest: Interactable
	var nearest_distance: float = INF
	for candidate: Node in get_tree().get_nodes_in_group(&"interactables"):
		var item: Interactable = candidate as Interactable
		if not is_instance_valid(item) or not item.is_available() or not item.is_visible_in_tree():
			continue
		var distance: float = player.global_position.distance_squared_to(item.global_position)
		if distance > minf(24.0, item.radius) ** 2:
			continue
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			player.global_position, item.global_position, 1)
		query.hit_from_inside = true
		if not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			continue
		if distance < nearest_distance:
			nearest = item
			nearest_distance = distance
		# Empates conservan orden del árbol.
	return nearest


func _set_focus(item: Interactable) -> void:
	if is_instance_valid(focused):
		focused.set_focused(false)
	focused = item
	if is_instance_valid(focused):
		focused.set_focused(true)
	var hud: Node = get_tree().get_first_node_in_group(&"game_hud")
	if is_instance_valid(hud) and hud.has_method("set_prompt"):
		hud.call("set_prompt", focused.display_name if is_instance_valid(focused) else "")
