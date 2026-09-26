extends Area2D
## Colocar como MusicRegionA/B/C o configurar region_id. No edita salas.

@export_enum("auto", "A", "B", "C") var region_id: String = "auto"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		activate()


func activate() -> void:
	MusicDirector.set_region(StringName(name) if region_id == "auto" else StringName(region_id))
