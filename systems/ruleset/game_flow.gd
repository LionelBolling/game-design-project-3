class_name GameFlow
extends Node
## The end of a run: the caught screen, or the intruder reveal and then the
## escaped screen, and R to restart (SYSTEM.md §6 Q6 and Q11, D-016).
## Display only: it reads the board and never writes it.

# The GDD palette (docs/ART.md).
const BLACK := Color("242522")
const KETCHUP := Color("731f24")
const MUSTARD := Color("b39839")
const BONE := Color("c9c1a5")
const MINT := Color("91cba5") # the accent: the way out
const SKIN := Color("b98a6a")
const WIG := Color("9c2a24")
## Seconds the reveal plays before the escaped screen.
const REVEAL_TIME := 4.0

## &"" while playing, then &"caught", or &"reveal" followed by &"escaped".
var screen: StringName = &""

var _world := Node3D.new()
var _layer := CanvasLayer.new()
var _backdrop := ColorRect.new()
var _title := Label.new()
var _hint := Label.new()
var _reveal_left := 0.0
var _last_state: BoardTypes.Game = BoardTypes.Game.PLAYING
var _director: Director


## Which screen a game state ends on.
static func screen_for(state: BoardTypes.Game) -> StringName:
	match state:
		BoardTypes.Game.CAUGHT:
			return &"caught"
		BoardTypes.Game.ESCAPED:
			return &"escaped"
	return &""


func _ready() -> void:
	add_child(_world)
	_layer.layer = 20
	add_child(_layer)
	_backdrop.color = BLACK
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_backdrop)
	_style_label(_title, 52, -24.0)
	_style_label(_hint, 20, 44.0)
	_hide_screen()


func _process(delta: float) -> void:
	if _director == null:
		_director = get_tree().get_first_node_in_group(Director.GROUP) as Director
	if _director != null:
		var state := _director.board.game_state
		if state != _last_state:
			_last_state = state
			show_for(state, _director.board.enemy_position)
	advance(delta)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var on_end_screen := screen == &"caught" or screen == &"escaped"
	if on_end_screen and key and key.pressed and not key.echo and key.physical_keycode == KEY_R:
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()


## Start the end-of-run sequence for a game state.
func show_for(state: BoardTypes.Game, ronald_at: Vector3) -> void:
	match state:
		BoardTypes.Game.CAUGHT:
			screen = &"caught"
			_show_screen("YOU WERE CAUGHT", "Press R to try again", BONE, MUSTARD)
		BoardTypes.Game.ESCAPED:
			screen = &"reveal"
			_reveal_left = REVEAL_TIME
			place_reveal(ronald_at)
			_hide_screen()
		_:
			screen = &""
			_hide_screen()


## Count down the reveal, then show the escaped screen.
func advance(delta: float) -> void:
	if screen != &"reveal":
		return
	_reveal_left -= delta
	if _reveal_left <= 0.0:
		screen = &"escaped"
		_show_screen("YOU GOT OUT", "Press R to play again", MINT, BONE)


func is_screen_visible() -> bool:
	return _backdrop.visible


## Where the end screen's backdrop is drawn, for tests.
func screen_rect() -> Rect2:
	return _backdrop.get_global_rect()


## The intruder reveal: a man in a cheap clown suit standing where Ronald was,
## lit from above. A low-poly placeholder until the real model exists (D-016).
func place_reveal(at: Vector3) -> Node3D:
	var figure := Node3D.new()
	_world.add_child(figure)
	figure.position = at # _world sits at the world origin (GameFlow is a plain Node)
	_box(figure, Vector3(0.5, 0.75, 0.3), Vector3(0, 1.05, 0), MUSTARD) # suit
	_box(figure, Vector3(0.08, 0.75, 0.32), Vector3(0, 1.05, 0), KETCHUP) # stripe
	_box(figure, Vector3(0.18, 0.7, 0.2), Vector3(-0.13, 0.35, 0), MUSTARD) # legs
	_box(figure, Vector3(0.18, 0.7, 0.2), Vector3(0.13, 0.35, 0), MUSTARD)
	_box(figure, Vector3(0.14, 0.62, 0.16), Vector3(-0.33, 1.05, 0), KETCHUP) # arms
	_box(figure, Vector3(0.14, 0.62, 0.16), Vector3(0.33, 1.05, 0), KETCHUP)
	_ball(figure, 0.14, Vector3(0, 1.58, 0), SKIN) # a real face, no paint
	_ball(figure, 0.17, Vector3(0, 1.66, -0.04), WIG) # the cheap wig
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.6, 0.6)
	light.omni_range = 6.0
	light.light_energy = 2.5
	light.light_color = Color("fff1d6")
	figure.add_child(light)
	return figure


func _show_screen(title: String, hint: String, title_color: Color, hint_color: Color) -> void:
	_title.text = title
	_hint.text = hint
	_title.add_theme_color_override("font_color", title_color)
	_hint.add_theme_color_override("font_color", hint_color)
	for node: CanvasItem in [_backdrop, _title, _hint]:
		node.visible = true


func _hide_screen() -> void:
	for node: CanvasItem in [_backdrop, _title, _hint]:
		node.visible = false


func _style_label(label: Label, size: int, offset_y: float) -> void:
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_top = offset_y
	label.offset_bottom = offset_y
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	_layer.add_child(label)


# Chunky, flat-shaded PS1-style parts (docs/ART.md).
func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_part(parent, mesh, at, color)


func _ball(parent: Node3D, radius: float, at: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	_part(parent, mesh, at, color)


func _part(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.roughness = 1.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
