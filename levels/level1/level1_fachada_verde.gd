extends Node2D
## Authored host: reuse the integrated UI's restart and quit contract.
@onready var flow: UIFlow = $UIFlow

func _ready() -> void:
	flow.restart_requested.connect(_on_restart_requested)
	flow.quit_requested.connect(_on_quit_requested)

func _on_restart_requested(_reason: StringName) -> void:
	get_tree().call_deferred("reload_current_scene")

func _on_quit_requested() -> void:
	flow.open_screen(&"main")
