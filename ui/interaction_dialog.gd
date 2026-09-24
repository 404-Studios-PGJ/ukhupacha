class_name InteractionDialog
extends CanvasLayer

var _player: Node
var _locked_player: bool = false
var _prior_input: bool = false
var _body: Label
var _choices: VBoxContainer
var _puzzle: PuzzleTerminalView


func setup(player: Node, heading: String, body: String) -> void:
	_player = player
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root: Control = Control.new()
	add_child(root)
	UIBuild.screen(root)
	UIBuild.panel(root, Rect2(0, 0, 640, 360))
	UIBuild.header(root, heading, "ARCHIVO / HELIX")
	UIBuild.panel(root, Rect2(24, 64, 592, 242), &"Dossier")
	var panel: VBoxContainer = VBoxContainer.new()
	UIBuild.place(panel, root, Rect2(42, 80, 556, 210))
	_body = UIBuild.label(panel, body, Rect2(0, 0, 556, 94))
	_body.custom_minimum_size = Vector2(556, 94)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_choices = VBoxContainer.new()
	panel.add_child(_choices)
	if is_instance_valid(_player) and _player.has_method("set_input_enabled"):
		_prior_input = UIBuild.input_enabled(_player)
		_player.call("set_input_enabled", false)
		_locked_player = true
	Level1Progress.progress_reset.connect(close)


func setup_puzzle(player: Node, terminal: Node) -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_puzzle = preload("res://ui/puzzle_terminal.tscn").instantiate() as PuzzleTerminalView
	_puzzle.player = player
	_puzzle.terminal = terminal
	_puzzle.closed.connect(close)
	add_child(_puzzle)


func add_choice(caption: String, action: Callable) -> Button:
	var button: Button = UIBuild.button(_choices, caption, Rect2(0, 0, 556, 32), action, true)
	button.custom_minimum_size.y = 32
	if _choices.get_child_count() == 1:
		button.grab_focus()
	return button


func set_body(body: String) -> void:
	_body.text = body


func close() -> void:
	_release()
	queue_free()


func _release() -> void:
	if is_instance_valid(_player) and _locked_player:
		_player.call("set_input_enabled", _prior_input)
	_locked_player = false
	if is_instance_valid(_puzzle):
		_puzzle._release()


func _exit_tree() -> void:
	_release()
