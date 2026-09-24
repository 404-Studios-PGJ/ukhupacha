extends Node
## Estado único de Nivel 1. La implementación completa sigue en feat/level-interactions.

signal progress_reset()


func reset() -> void:
	progress_reset.emit()
