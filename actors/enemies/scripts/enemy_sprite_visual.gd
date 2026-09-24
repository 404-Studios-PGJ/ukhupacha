class_name EnemySpriteVisual extends Node2D
## Aspecto con hojas de sprites (frames en una fila, mirando a la derecha).
## Los ataques no usan fps: el frame sale del avance de windup, golpe y
## recuperación, así el impacto siempre coincide con el AttackArea encendido.

const STAR_COLOR : Color = Color("ffd23f")
const CRITICAL_TINT : Color = Color(1.0, 0.85, 0.3)

@export_group("Hojas")
@export var idle_sheet : Texture2D
@export var walk_sheet : Texture2D
## Se reproduce durante la sospecha ("?").
@export var alert_sheet : Texture2D
@export var white_attack_sheet : Texture2D
@export var red_attack_sheet : Texture2D
## Frame 0 = golpeado; frame 1 = silueta clara para el destello.
@export var hurt_sheet : Texture2D
@export var death_sheet : Texture2D
@export var frame_size : Vector2i = Vector2i(96, 96)
## Columna del centro del cuerpo dentro del frame, para alinear los pies.
@export var body_center_x : float = 48.0

@export_group("Frames de ataque")
## Frames de cada fase, repartidos en su duración; -1 = frame de reposo.
@export var white_windup_frames : PackedInt32Array = PackedInt32Array([0])
@export var white_active_frames : PackedInt32Array = PackedInt32Array([0])
@export var white_recovery_frames : PackedInt32Array = PackedInt32Array([0])
@export var red_windup_frames : PackedInt32Array = PackedInt32Array([0])
@export var red_active_frames : PackedInt32Array = PackedInt32Array([0])
@export var red_recovery_frames : PackedInt32Array = PackedInt32Array([0])

@export_group("Ritmo y detalles")
@export var idle_fps : float = 6.0
@export var walk_fps : float = 10.0
@export var death_time : float = 0.6
## Altura de la barra de vida y de las estrellas del stagger.
@export var head_y : float = -70.0

var _t : float = 0.0
var _flash_time : float = 0.0
var _flash_critical : bool = false
var _dead_time : float = 0.0

@onready var enemy : EnemyBase = get_parent()
@onready var sprite : Sprite2D = $Sprite2D


func flash(critical: bool) -> void:
	_flash_time = 0.2 if critical else 0.1
	_flash_critical = critical


func _process(delta: float) -> void:
	_t += delta
	_flash_time = maxf(_flash_time - delta, 0.0)
	if absf(enemy.facing.x) > 0.1:
		sprite.flip_h = enemy.facing.x < 0.0
	var offset_x := frame_size.x / 2.0 - body_center_x
	sprite.position = Vector2(-offset_x if sprite.flip_h else offset_x, -frame_size.y / 2.0)
	sprite.modulate = Color.WHITE

	match enemy.state:
		EnemyBase.State.DEAD:
			_dead_time += delta
			_show_progress(death_sheet, _dead_time / death_time)
		EnemyBase.State.WINDUP:
			_show_attack_phase(white_windup_frames, red_windup_frames)
		EnemyBase.State.ACTIVE:
			_show_attack_phase(white_active_frames, red_active_frames)
		EnemyBase.State.RECOVERY:
			_show_attack_phase(white_recovery_frames, red_recovery_frames)
		EnemyBase.State.SUSPICIOUS:
			_show_progress(alert_sheet, enemy.state_progress())
		EnemyBase.State.HURT:
			_show(hurt_sheet, 0)
		EnemyBase.State.STAGGER:
			_show(hurt_sheet, 0)
			sprite.position.x += sin(_t * 40.0)
		_:
			if enemy.velocity.length() > 1.0:
				_show_loop(walk_sheet, walk_fps)
			else:
				_show_loop(idle_sheet, idle_fps)

	if _flash_time > 0.0 and enemy.state != EnemyBase.State.DEAD:
		_show(hurt_sheet, 1)
		if _flash_critical:
			sprite.modulate = CRITICAL_TINT
	queue_redraw()


func _draw() -> void:
	if enemy.state == EnemyBase.State.DEAD:
		return
	var head := Vector2(0, head_y)
	if enemy.state == EnemyBase.State.STAGGER:
		for i in 3:
			var angle := _t * 6.0 + i * TAU / 3.0
			draw_circle(head + Vector2(cos(angle) * 14.0, sin(angle) * 4.0 + 6.0), 2.0, STAR_COLOR)
	if enemy.hp < enemy.stats.max_hp:
		var ratio := enemy.hp / enemy.stats.max_hp
		draw_rect(Rect2(head.x - 16, head.y, 32, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(head.x - 16, head.y, 32 * ratio, 3), Color("e63946"))


func _show_attack_phase(white_frames: PackedInt32Array, red_frames: PackedInt32Array) -> void:
	var red := enemy.current_attack != null and enemy.current_attack.kind == EnemyAttack.Kind.RED
	var frames := red_frames if red else white_frames
	var index := mini(int(enemy.state_progress() * frames.size()), frames.size() - 1)
	if frames[index] < 0:
		_show(idle_sheet, 0)
	else:
		_show(red_attack_sheet if red else white_attack_sheet, frames[index])


func _show_progress(sheet: Texture2D, progress: float) -> void:
	var count := _frame_count(sheet)
	_show(sheet, mini(int(clampf(progress, 0.0, 1.0) * count), count - 1))


func _show_loop(sheet: Texture2D, fps: float) -> void:
	_show(sheet, int(_t * fps) % _frame_count(sheet))


func _show(sheet: Texture2D, frame: int) -> void:
	if sheet == null:
		return
	if sprite.texture != sheet:
		sprite.texture = sheet
		sprite.hframes = _frame_count(sheet)
	sprite.frame = clampi(frame, 0, sprite.hframes - 1)


func _frame_count(sheet: Texture2D) -> int:
	return maxi(sheet.get_width() / frame_size.x, 1) if sheet else 1
