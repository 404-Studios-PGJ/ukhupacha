extends Node2D
## Provisional host built from Gian's enemy lab; the original lab remains intact.

@onready var player: Player = $Player
@onready var flow: UIFlow = $UIFlow


func _ready() -> void:
	flow.restart_requested.connect(_on_restart_requested)
	flow.quit_requested.connect(_on_quit_requested)
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		MusicDirector.watch_enemy(enemy)


func _on_restart_requested(_reason: StringName) -> void:
	get_tree().call_deferred("reload_current_scene")


func _on_quit_requested() -> void:
	flow.open_screen(&"main")
