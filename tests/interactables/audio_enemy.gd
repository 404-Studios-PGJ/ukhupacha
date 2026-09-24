extends Node
## Doble del contrato de Gian.
signal enemy_alerted(enemy: Node)
signal enemy_died(enemy: Node)


func alert() -> void:
	enemy_alerted.emit(self)


func die() -> void:
	enemy_died.emit(self)
