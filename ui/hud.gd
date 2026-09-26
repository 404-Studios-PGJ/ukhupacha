class_name GameHUD
extends CanvasLayer

var player: Node
var snapshot: Dictionary = {}
var _health: TextureRect
var _stamina: TextureRect
var _hp_text: Label
var _st_text: Label
var _weapon: Control
var _shield: Control
var _health_visual: Control
var _stamina_visual: Control
var _prompt_nodes: Array[Control] = []
var _prompt_text: Label
var _prompt_visible := false
var _health_tween: Tween
var _stamina_tween: Tween
var _weapon_tween: Tween
var _shield_tween: Tween
var _prompt_tween: Tween
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
var _hud_enter_nodes: Array[Control] = []


func _ready() -> void:
	if get_tree().get_first_node_in_group(&"game_hud") != null:
		queue_free()
		return
	add_to_group(&"game_hud")
	layer = 10
	var root: Control = $SafeArea
	UIBuild.screen(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health = $SafeArea/HealthBarFill
	_stamina = $SafeArea/StaminaBarFill
	_hp_text = $SafeArea/HealthLabel
	_st_text = $SafeArea/StaminaLabel
	_weapon = $SafeArea/WeaponIcon2
	_shield = $SafeArea/ShieldIcon2
	_health_visual = $SafeArea/VitalsFrame
	_stamina_visual = $SafeArea/VitalsFrame
	_prompt_text = $SafeArea/InteractionText
	_prompt_nodes = [$SafeArea/InteractionPopup, $SafeArea/InteractionMarker, $SafeArea/InteractionText, $SafeArea/InteractionHint]
	_hud_enter_nodes = [
		$SafeArea/VitalsFrame,
		$SafeArea/HealthIcon,
		$SafeArea/HealthBarFrame,
		$SafeArea/HealthBarFill,
		$SafeArea/StaminaIcon,
		$SafeArea/StaminaBarFrame,
		$SafeArea/StaminaBarFill,
		$SafeArea/HealthLabel,
		$SafeArea/StaminaLabel,
		$SafeArea/LoadoutFrame,
		$SafeArea/WeaponCaption,
		$SafeArea/ShieldCaption,
		$SafeArea/WeaponCaption3,
		$SafeArea/WeaponIcon2,
		$SafeArea/WeaponIcon3,
		$SafeArea/ShieldIcon2,
		$WeaponSlot,
		$WeaponSlot2,
		$ShieldSlot,
	]
	for node: Control in _prompt_nodes:
		node.visible = false
	_prompt_visible = false
	bind_player(player if is_instance_valid(player) else get_tree().get_first_node_in_group(&"player"))
	call_deferred("_play_hud_enter")


func _play_hud_enter() -> void:
	for node: Control in _hud_enter_nodes:
		node.pivot_offset = node.size * 0.5
	_animation_player.play("hud_enter")


func bind_player(value: Node) -> void:
	if not is_instance_valid(_health):
		player = value
		return
	for pair: Array in [["health_changed", _on_health], ["stamina_changed", _on_stamina], ["equipment_changed", _on_equipment]]:
		if is_instance_valid(player) and player.has_signal(pair[0]) and player.is_connected(pair[0], pair[1]):
			player.disconnect(pair[0], pair[1])
	player = value
	snapshot = UIBuild.state(player)
	_on_health(float(snapshot.get("health", 0)), float(snapshot.get("max_health", 100)))
	_on_stamina(float(snapshot.get("stamina", 0)), float(snapshot.get("max_stamina", 100)))
	_on_equipment(snapshot.get("weapon_id", &"none"), bool(snapshot.get("shield", false)), int(snapshot.get("tier", 0)))
	if not is_instance_valid(player):
		return
	for pair: Array in [["health_changed", _on_health], ["stamina_changed", _on_stamina], ["equipment_changed", _on_equipment]]:
		if player.has_signal(pair[0]):
			player.connect(pair[0], pair[1])


func _on_health(current: float, maximum: float) -> void:
	var decreased := snapshot.has("health") and current < float(snapshot.get("health", current))
	snapshot["health"] = current
	snapshot["max_health"] = maximum
	_health.size.x = 118.0 * clampf(current / maxf(1.0, maximum), 0.0, 1.0)
	_hp_text.text = "%d / %d" % [int(current), int(maximum)]
	if decreased:
		_pulse_scale(_health_visual, _health_tween, Vector2(0.96, 0.96), 0.05, Vector2(1.02, 1.02), 0.06, 0.08, "health")


func _on_stamina(current: float, maximum: float) -> void:
	var decreased := snapshot.has("stamina") and current < float(snapshot.get("stamina", current))
	snapshot["stamina"] = current
	snapshot["max_stamina"] = maximum
	_stamina.size.x = 91.0 * clampf(current / maxf(1.0, maximum), 0.0, 1.0)
	_st_text.text = "STAMINA %d" % int(current)
	if decreased:
		_pulse_scale(_stamina_visual, _stamina_tween, Vector2(0.97, 0.97), 0.05, Vector2.ONE, 0.08, 0.0, "stamina")


func _on_equipment(weapon_id: StringName, shield: bool, tier: int) -> void:
	var weapon_changed: bool = snapshot.has("weapon_id") and weapon_id != snapshot.get("weapon_id", weapon_id)
	var shield_changed: bool = snapshot.has("shield") and shield != bool(snapshot.get("shield", shield))
	snapshot.merge({"weapon_id": weapon_id, "shield": shield, "tier": tier}, true)
	_weapon.modulate.a = 1.0 if weapon_id != &"none" else 0.35
	_shield.modulate.a = 1.0 if shield else 0.35
	if weapon_changed:
		_pulse_icon(_weapon, _weapon_tween, "weapon")
	if shield_changed:
		_pulse_icon(_shield, _shield_tween, "shield")


func set_prompt(text: String) -> void:
	_prompt_text.text = "E  " + text.to_upper()
	var should_show := not text.is_empty()
	if should_show == _prompt_visible:
		return
	_prompt_visible = should_show
	if should_show:
		_start_prompt_enter()
	else:
		_start_prompt_exit()


func _pulse_scale(target: Control, tween: Tween, first_scale: Vector2, first_duration: float, second_scale: Vector2, second_duration: float, final_duration: float, _kind: StringName) -> void:
	if target == null:
		return
	if tween != null and tween.is_valid():
		tween.kill()
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2.ONE
	var next := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	next.tween_property(target, "scale", first_scale, first_duration)
	if second_duration > 0.0:
		next.tween_property(target, "scale", second_scale, second_duration)
	if final_duration > 0.0:
		next.tween_property(target, "scale", Vector2.ONE, final_duration)
	_set_tween_reference(_kind, next)


func _pulse_icon(target: Control, tween: Tween, kind: StringName) -> void:
	if target == null:
		return
	if tween != null and tween.is_valid():
		tween.kill()
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2.ONE
	var next := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	next.tween_property(target, "scale", Vector2(0.90, 0.90), 0.05)
	next.tween_property(target, "scale", Vector2(1.06, 1.06), 0.07)
	next.tween_property(target, "scale", Vector2.ONE, 0.08)
	_set_tween_reference(kind, next)


func _set_tween_reference(kind: StringName, tween: Tween) -> void:
	match kind:
		"health": _health_tween = tween
		"stamina": _stamina_tween = tween
		"weapon": _weapon_tween = tween
		"shield": _shield_tween = tween


func _start_prompt_enter() -> void:
	if _prompt_tween != null and _prompt_tween.is_valid():
		_prompt_tween.kill()
	for node: Control in _prompt_nodes:
		node.visible = true
		node.pivot_offset = node.size * 0.5
		node.modulate.a = 0.0
		node.scale = Vector2(0.96, 0.96)
	_prompt_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for node: Control in _prompt_nodes:
		_prompt_tween.tween_property(node, "modulate:a", 1.0, 0.12)
		_prompt_tween.tween_property(node, "scale", Vector2.ONE, 0.12)


func _start_prompt_exit() -> void:
	if _prompt_tween != null and _prompt_tween.is_valid():
		_prompt_tween.kill()
	_prompt_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for node: Control in _prompt_nodes:
		node.pivot_offset = node.size * 0.5
		_prompt_tween.tween_property(node, "modulate:a", 0.0, 0.10)
		_prompt_tween.tween_property(node, "scale", Vector2(0.98, 0.98), 0.10)
	_prompt_tween.finished.connect(_finish_prompt_exit, CONNECT_ONE_SHOT)


func _finish_prompt_exit() -> void:
	for node: Control in _prompt_nodes:
		node.visible = false
		node.scale = Vector2.ONE
