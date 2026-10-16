extends Node3D
## Top-down sandbox for the blackboard. The Director runs whatever systems are
## plugged in under it (all four stubs at first). This script only reads the
## board and draws it as markers, so you can watch the systems work together.
##
## Keys: WASD or arrows move the player, H hides, F picks up a fuse,
## B restores the breaker, hold X for the exit zone, F2 shows the board,
## R restarts. To try your real system, replace your stub
## under Director with it, in the same place in the order.


const MODE_COLORS: Dictionary[BoardTypes.Mode, Color] = {
	BoardTypes.Mode.PATROL: Color("e8b64b"),
	BoardTypes.Mode.INVESTIGATE: Color("e07a2e"),
	BoardTypes.Mode.CHASE: Color("d22b2b"),
	BoardTypes.Mode.DORMANT: Color("555555"),
	BoardTypes.Mode.POSE: Color("c9c1a5"),
	BoardTypes.Mode.SEEK: Color("b03aa0"),
	BoardTypes.Mode.CAMP: Color("91cba5"),
	BoardTypes.Mode.CATCH: Color("f3eee2"),
}
## Modes in which Roaming ignores target_position, so there's no target to draw.
const NO_TARGET_MODES: Array[BoardTypes.Mode] = [BoardTypes.Mode.PATROL, BoardTypes.Mode.DORMANT, BoardTypes.Mode.POSE]
const PLAYER_EXPOSED := Color("3f7fe0")
const PLAYER_HIDDEN := Color("3a3d44")

@onready var _director: Director = $Director

var _player_mat := _flat(PLAYER_EXPOSED)
var _ronald_mat := _flat(MODE_COLORS[BoardTypes.Mode.PATROL])
var _player: MeshInstance3D
var _ronald: MeshInstance3D
var _target: MeshInstance3D
var _status := Label.new()


func _ready() -> void:
	_build_world()
	_player = _capsule(0.3, 1.1, _player_mat) # kid-sized
	_ronald = _capsule(0.4, 1.9, _ronald_mat) # adult-sized
	var disc := CylinderMesh.new()
	disc.top_radius = 0.25
	disc.bottom_radius = 0.25
	disc.height = 0.02
	disc.material = _flat(Color("f3eee2"))
	_target = MeshInstance3D.new()
	_target.mesh = disc
	add_child(_target)

	var overlay := BoardOverlay.new()
	overlay.director = _director
	add_child(overlay)
	var hud := CanvasLayer.new()
	add_child(hud)
	hud.add_child(_status)
	_status.add_theme_font_size_override("font_size", 16)
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)


func _process(_delta: float) -> void:
	var board := _director.board
	_player.position = board.player_position + Vector3.UP * 0.55
	var exposed := board.hide_state == BoardTypes.Hide.EXPOSED
	_player_mat.albedo_color = PLAYER_EXPOSED if exposed else PLAYER_HIDDEN
	_ronald.position = board.enemy_position + Vector3.UP * 0.95
	_ronald.visible = board.ronald_mode != BoardTypes.Mode.DORMANT
	_ronald_mat.albedo_color = MODE_COLORS[board.ronald_mode]
	_target.position = board.target_position + Vector3.UP * 0.02
	_target.visible = not NO_TARGET_MODES.has(board.ronald_mode)
	match board.game_state:
		BoardTypes.Game.CAUGHT:
			_status.text = "CAUGHT. Press R to restart."
		BoardTypes.Game.ESCAPED:
			_status.text = "ESCAPED. Press R to restart."
		_:
			_status.text = "WASD move   H hide   F fuse (%d/3)   B breaker   hold X exit   F2 board   R restart" % board.fuses_collected


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func _build_world() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 16)
	plane.material = _flat(Color("23262b"))
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	add_child(ground)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18.0
	camera.position = Vector3(0, 20, 0)
	camera.rotation_degrees = Vector3(-90, 0, 0)
	add_child(camera)
	camera.make_current()


func _capsule(radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	add_child(node)
	return node


static func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material
