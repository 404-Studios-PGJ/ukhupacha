class_name EnemyManaSeedVisual extends Node2D
## Aspecto de los guardias con hojas Mana Seed (frames de 64x64, 8x8 por
## página). Cada fila de 4 es una dirección: abajo, arriba, derecha, izquierda.
## - Patrulla con el arma envainada (p1) y la desenvaina al sospechar (pONE1).
## - En combate usa pONE2 (guardia y paso de combate) y pONE3 (ataques).
## - Los frames de ataque avanzan con state_progress(): el impacto coincide
##   con la ventana activa del AttackArea.

const COLUMNS : int = 8
const SHEATH_TIME : float = 0.3
const HIT_FRAME : int = 5
const FLASH_COLOR : Color = Color(2.2, 2.2, 2.2)
const CRITICAL_COLOR : Color = Color(2.2, 1.8, 0.6)

@export_group("Hojas")
## Página 1: de pie y caminando, sin arma.
@export var walk_sheet : Texture2D
## Desenvainar, recibir golpe y caída.
@export var reaction_sheet : Texture2D
## Guardia de combate y paso de combate.
@export var combat_sheet : Texture2D
## Tajos, estocada y golpe de escudo.
@export var attack_sheet : Texture2D

@export_group("Ataques (columnas de la hoja de ataques)")
## Mitad de la hoja: 0 = filas 0-3, 1 = filas 4-7.
@export var white_half : int = 0
@export var white_windup : PackedInt32Array = PackedInt32Array([0])
@export var white_active : PackedInt32Array = PackedInt32Array([1, 2])
@export var white_recovery : PackedInt32Array = PackedInt32Array([3])
@export var red_half : int = 0
@export var red_windup : PackedInt32Array = PackedInt32Array([4])
@export var red_active : PackedInt32Array = PackedInt32Array([5, 6])
@export var red_recovery : PackedInt32Array = PackedInt32Array([7])
## Disparo: la estocada (mitad 1) con el brazo extendido apuntando.
@export var ranged_half : int = 1
@export var ranged_windup : PackedInt32Array = PackedInt32Array([0])
@export var ranged_active : PackedInt32Array = PackedInt32Array([1, 2])
@export var ranged_recovery : PackedInt32Array = PackedInt32Array([3])
## Pose de bloqueo al frenar un golpe del Player (mitad 1, columna 4).
@export var block_frame : int = 4
@export var block_half : int = 1

@export_group("Ritmo y detalles")
@export var walk_fps : float = 7.4
@export var combat_idle_fps : float = 5.0
@export var combat_move_fps : float = 6.0
@export var death_time : float = 0.7
@export var head_y : float = -38.0

var _t : float = 0.0
var _flash_time : float = 0.0
var _flash_critical : bool = false
var _block_time : float = 0.0
var _sheath_time : float = 0.0
var _was_armed : bool = false
var _dead_time : float = 0.0
# Columnas de la hoja de reacciones: caída con rebote y desenvainar.
var _death_frames : PackedInt32Array = PackedInt32Array([5, 6, 7, 6, 7])
var _draw_frames : PackedInt32Array = PackedInt32Array([0, 1, 2])

@onready var enemy : EnemyBase = get_parent()
@onready var sprite : Sprite2D = $Sprite2D


func flash(critical: bool) -> void:
	_flash_time = 0.2 if critical else 0.1
	_flash_critical = critical


## Muestra la pose de bloqueo un instante (golpe frenado por el escudo).
func block() -> void:
	_block_time = 0.25


func _process(delta: float) -> void:
	_t += delta
	_flash_time = maxf(_flash_time - delta, 0.0)
	_block_time = maxf(_block_time - delta, 0.0)
	_sheath_time = maxf(_sheath_time - delta, 0.0)
	sprite.modulate = Color.WHITE
	sprite.position.x = 0.0

	var armed := _is_armed()
	if _was_armed and not armed:
		_sheath_time = SHEATH_TIME
	_was_armed = armed

	match enemy.state:
		EnemyBase.State.DEAD:
			_dead_time += delta
			_show_sequence(reaction_sheet, 0, _death_frames, _dead_time / death_time)
		EnemyBase.State.WINDUP:
			_show_attack(white_windup, red_windup, ranged_windup)
		EnemyBase.State.ACTIVE:
			_show_attack(white_active, red_active, ranged_active)
		EnemyBase.State.RECOVERY:
			_show_attack(white_recovery, red_recovery, ranged_recovery)
		EnemyBase.State.SUSPICIOUS:
			_show_sequence(reaction_sheet, 0, _draw_frames, enemy.state_progress())
		EnemyBase.State.HURT:
			_show(reaction_sheet, 0, HIT_FRAME)
		EnemyBase.State.STAGGER:
			_show(reaction_sheet, 0, HIT_FRAME)
			sprite.position.x = sin(_t * 40.0)
		_:
			_show_movement(armed)

	if _block_time > 0.0 and enemy.state != EnemyBase.State.DEAD:
		_show(attack_sheet, block_half, block_frame)
	if _flash_time > 0.0 and enemy.state != EnemyBase.State.DEAD:
		sprite.modulate = CRITICAL_COLOR if _flash_critical else FLASH_COLOR
	queue_redraw()


func _draw() -> void:
	EnemyOverlay.draw_shadow(self, 16.0)
	if enemy.state == EnemyBase.State.DEAD:
		return
	var head := Vector2(0, head_y)
	if enemy.state == EnemyBase.State.STAGGER:
		EnemyOverlay.draw_stun_stars(self, head, _t, 8.0)
	if enemy.hp < enemy.stats.max_hp:
		EnemyOverlay.draw_hp_bar(self, head, enemy.hp / enemy.stats.max_hp)


## Fuera de patrulla lleva el arma en la mano.
func _is_armed() -> bool:
	return enemy.state != EnemyBase.State.IDLE and enemy.state != EnemyBase.State.PATROL


func _show_movement(armed: bool) -> void:
	var moving := enemy.velocity.length() > 1.0
	if _sheath_time > 0.0:
		# Envainar: desenvainar al revés.
		_show_sequence(reaction_sheet, 0, _draw_frames, _sheath_time / SHEATH_TIME)
	elif armed:
		if moving:
			_show(combat_sheet, 0, 4 + int(_t * combat_move_fps) % 4)
		else:
			_show(combat_sheet, 0, int(_t * combat_idle_fps) % 4)
	elif moving:
		_show(walk_sheet, 1, int(_t * walk_fps) % 6)
	else:
		_show(walk_sheet, 0, 0)


func _show_attack(white_frames: PackedInt32Array, red_frames: PackedInt32Array,
		ranged_frames: PackedInt32Array) -> void:
	var attack := enemy.current_attack
	if attack != null and attack.ranged:
		_show_sequence(attack_sheet, ranged_half, ranged_frames, enemy.state_progress())
		return
	var red := attack != null and attack.kind == EnemyAttack.Kind.RED
	_show_sequence(attack_sheet, red_half if red else white_half,
			red_frames if red else white_frames, enemy.state_progress())


func _show_sequence(sheet: Texture2D, half: int, frames: PackedInt32Array, progress: float) -> void:
	var index := mini(int(clampf(progress, 0.0, 1.0) * frames.size()), frames.size() - 1)
	_show(sheet, half, frames[index])


## Fila según la mitad de la hoja (0 o 1) y la dirección a la que mira.
func _show(sheet: Texture2D, half: int, column: int) -> void:
	if sheet == null:
		return
	if sprite.texture != sheet:
		sprite.texture = sheet
		sprite.hframes = COLUMNS
		sprite.vframes = COLUMNS
	sprite.frame = (half * 4 + _direction_row()) * COLUMNS + column


func _direction_row() -> int:
	var f := enemy.facing
	if absf(f.x) > absf(f.y):
		return 2 if f.x > 0.0 else 3
	return 0 if f.y >= 0.0 else 1
