extends Node2D

@export var max_health: float = 100.0
var current_health: float = 100.0
var is_staggered: bool = false
var stagger_timer: float = 0.0

@onready var lbl_damage: Label = $LabelDamage
@onready var sprite: ColorRect = $VisualBox

func _ready() -> void:
	current_health = max_health
	_update_label("Dummy Listo")

func _process(delta: float) -> void:
	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			is_staggered = false
			if sprite != null:
				sprite.color = Color(0.8, 0.4, 0.2, 1.0)
			_update_label("HP: %.0f" % current_health)

func take_hit(amount: float, _source: Node, was_critical: bool = false) -> void:
	current_health = max(0.0, current_health - amount)
	var crit_text = " ¡CRÍTICO 2X!" if was_critical else ""
	_update_label("-%0.1f HP%s (Total: %.0f)" % [amount, crit_text, current_health])
	
	if sprite != null:
		sprite.color = Color(1.0, 1.0, 1.0, 1.0)
		var tween = create_tween()
		var target_col = Color(0.9, 0.9, 0.2, 1.0) if is_staggered else Color(0.8, 0.4, 0.2, 1.0)
		tween.tween_property(sprite, "color", target_col, 0.15)

func stagger(seconds: float) -> void:
	is_staggered = true
	stagger_timer = seconds
	if sprite != null:
		sprite.color = Color(0.9, 0.9, 0.2, 1.0)
	_update_label("¡STAGGER (%.1fs)!" % seconds)

func reset_dummy() -> void:
	current_health = max_health
	is_staggered = false
	stagger_timer = 0.0
	if sprite != null:
		sprite.color = Color(0.8, 0.4, 0.2, 1.0)
	_update_label("HP: %.0f" % current_health)

func _update_label(text: String) -> void:
	if lbl_damage != null:
		lbl_damage.text = text
