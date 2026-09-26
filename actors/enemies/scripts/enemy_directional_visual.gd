class_name EnemyDirectionalVisual extends Node2D
## Aspecto con una hoja por animación y 6 direcciones (una fila cada una):
## abajo, derecha-abajo, derecha-arriba, arriba, izquierda-arriba,
## izquierda-abajo. Las hojas se cargan según el look elegido.
## Los frames de ataque avanzan con state_progress(): el impacto coincide con
## la ventana activa del AttackArea.

## Ángulo de cada fila (grados, eje Y hacia abajo), en el orden de las hojas.
const ROW_ANGLES : Array[float] = [90.0, 30.0, -30.0, -90.0, -150.0, 150.0]
const FLASH_COLOR : Color = Color(2.2, 2.2, 2.2)
const CRITICAL_COLOR : Color = Color(2.2, 1.8, 0.6)

## Ruta de las hojas; {look} y {anim} se reemplazan al cargar.
@export var sheet_pattern : String = "res://actors/enemies/sprites/office/{look}/office_{look}_{anim}.png"
@export_enum("a", "b", "c", "aleatorio") var look : String = "a"
@export var frame_size : Vector2i = Vector2i(48, 64)

@export_group("Frames")
## Ataque (hoja "dash"): impulso, golpe y recuperación.
@export var attack_windup : PackedInt32Array = PackedInt32Array([1])
@export var attack_active : PackedInt32Array = PackedInt32Array([2, 3])
@export var attack_recovery : PackedInt32Array = PackedInt32Array([4, 5, 6, 7])
## Sobresalto al sospechar (hoja "jump").
@export var alert_frames : PackedInt32Array = PackedInt32Array([1, 2, 3, 4, 5, 6])
## Golpeado y aturdido (columna de la hoja "death").
@export var hit_frame : int = 1

@export_group("Ritmo y detalles")
@export var idle_fps : float = 8.0
@export var walk_fps : float = 10.0
@export var death_time : float = 0.8
@export var head_y : float = -32.0

var _sheets : Dictionary = {}
var _t : float = 0.0
var _flash_time : float = 0.0
var _flash_critical : bool = false
var _dead_time : float = 0.0

@onready var enemy : EnemyBase = get_parent()
@onready var sprite : Sprite2D = $Sprite2D


func _ready() -> void:
	var chosen := look
	if chosen == "aleatorio":
		chosen = ["a", "b", "c"].pick_random()
	for anim in ["idle", "walk", "dash", "jump", "death"]:
		_sheets[anim] = load(sheet_pattern.format({"look": chosen, "anim": anim}))


func flash(critical: bool) -> void:
	_flash_time = 0.2 if critical else 0.1
	_flash_critical = critical


func _process(delta: float) -> void:
	_t += delta
	_flash_time = maxf(_flash_time - delta, 0.0)
	sprite.modulate = Color.WHITE
	sprite.position.x = 0.0

	match enemy.state:
		EnemyBase.State.DEAD:
			_dead_time += delta
			_show_progress("death", _all_columns(), _dead_time / death_time)
		EnemyBase.State.WINDUP:
			_show_progress("dash", attack_windup, enemy.state_progress())
		EnemyBase.State.ACTIVE:
			_show_progress("dash", attack_active, enemy.state_progress())
		EnemyBase.State.RECOVERY:
			_show_progress("dash", attack_recovery, enemy.state_progress())
		EnemyBase.State.SUSPICIOUS:
			_show_progress("jump", alert_frames, enemy.state_progress())
		EnemyBase.State.HURT:
			_show("death", hit_frame)
		EnemyBase.State.STAGGER:
			_show("death", hit_frame)
			sprite.position.x = sin(_t * 40.0)
		_:
			if enemy.velocity.length() > 1.0:
				_show("walk", int(_t * walk_fps) % _columns("walk"))
			else:
				_show("idle", int(_t * idle_fps) % _columns("idle"))

	if _flash_time > 0.0 and enemy.state != EnemyBase.State.DEAD:
		sprite.modulate = CRITICAL_COLOR if _flash_critical else FLASH_COLOR
	queue_redraw()


func _draw() -> void:
	EnemyOverlay.draw_shadow(self, 12.0)
	if enemy.state == EnemyBase.State.DEAD:
		return
	var head := Vector2(0, head_y)
	if enemy.state == EnemyBase.State.STAGGER:
		EnemyOverlay.draw_stun_stars(self, head, _t, 7.0)
	if enemy.hp < enemy.stats.max_hp:
		EnemyOverlay.draw_hp_bar(self, head, enemy.hp / enemy.stats.max_hp)


func _show_progress(anim: String, frames: PackedInt32Array, progress: float) -> void:
	var index := mini(int(clampf(progress, 0.0, 1.0) * frames.size()), frames.size() - 1)
	_show(anim, frames[index])


func _show(anim: String, column: int) -> void:
	var sheet : Texture2D = _sheets.get(anim)
	if sheet == null:
		return
	if sprite.texture != sheet:
		sprite.texture = sheet
		sprite.hframes = _columns(anim)
		sprite.vframes = ROW_ANGLES.size()
	sprite.frame = _direction_row() * sprite.hframes + clampi(column, 0, sprite.hframes - 1)


func _columns(anim: String) -> int:
	var sheet : Texture2D = _sheets.get(anim)
	return maxi(sheet.get_width() / frame_size.x, 1) if sheet else 1


func _all_columns() -> PackedInt32Array:
	return PackedInt32Array(range(_columns("death")))


## Fila cuya dirección está más cerca de hacia dónde mira el enemigo.
func _direction_row() -> int:
	var angle := enemy.facing.angle()
	var best := 0
	var best_difference := INF
	for row in ROW_ANGLES.size():
		var difference := absf(angle_difference(angle, deg_to_rad(ROW_ANGLES[row])))
		if difference < best_difference:
			best = row
			best_difference = difference
	return best
