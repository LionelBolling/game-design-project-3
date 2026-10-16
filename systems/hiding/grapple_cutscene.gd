class_name GrappleCutscene
extends Node3D
const REQUIRED_PRESSES: int = 12
const STRUGGLE_SECONDS: float = 4.0
const PUSH_SECONDS: float = 0.7
const BITE_SECONDS: float = 1.0
var active: bool = false
var stage: StringName = &""
var presses: int = 0
var time_left: float = STRUGGLE_SECONDS
var hud: GrappleHud
var camera: Camera3D
var leap: CatchCutscene
var upper_jaw: Node3D
var lower_jaw: Node3D
var actor: Node3D
var _source: Camera3D
var _saved_actor: Transform3D
var _pin_transform: Transform3D
var _push_end: Transform3D
var _ground: Vector3
var _forward: Vector3
var _stage_time: float = 0.0
var _space_down: bool = false
var _paused: bool = false
var _won: Callable
var _lost: Callable
var _light: OmniLight3D
var _crunch: AudioStreamPlayer
var _hand: Node3D
var _hand_was_visible: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	leap = CatchCutscene.new()
	add_child(leap)
	leap.hold_seconds = 0.08
	leap.set_process(false)
	camera = Camera3D.new()
	camera.near = 0.015
	camera.fov = 75.0
	add_child(camera)
	_light = OmniLight3D.new()
	_light.light_energy = 0.8
	_light.omni_range = 4.0
	_light.hide()
	camera.add_child(_light)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	hud = GrappleHud.new()
	layer.add_child(hud)
	upper_jaw = _jaw(true)
	lower_jaw = _jaw(false)
	_crunch = AudioStreamPlayer.new()
	_crunch.stream = load("res://systems/hiding/bite_crunch.wav") as AudioStream
	_crunch.volume_db = -6.0
	add_child(_crunch)

func _process(delta: float) -> void:
	advance(delta)

func start(source: Camera3D, ronald: Node3D, won: Callable, lost: Callable) -> void:
	if active:
		return
	active = true
	stage = &"leap"
	_source = source
	_hand = source.get_node_or_null("Hand") as Node3D
	if _hand != null:
		_hand_was_visible = _hand.visible
		_hand.hide()
	actor = ronald
	_saved_actor = actor.global_transform
	_won = won
	_lost = lost
	_paused = false
	presses = 0
	_space_down = false
	_forward = -source.global_basis.z
	_forward.y = 0.0
	_forward = _forward.normalized() if _forward.length_squared() > 0.01 else Vector3.FORWARD
	_ground = Vector3(source.global_position.x, source.global_position.y - source.position.y, source.global_position.z)
	leap.start(source, actor, _begin_pin)

func _begin_pin() -> void:
	stage = &"struggle"
	time_left = STRUGGLE_SECONDS
	_stage_time = 0.0
	# The leap reaches into its own camera. Reset that pose before the pin
	# so his hands cannot intersect the new ground-level lens.
	var skeleton: Skeleton3D = actor.get("skeleton") as Skeleton3D
	if skeleton != null:
		skeleton.reset_bone_poses()
	var animation: AnimationPlayer = actor.get("animation") as AnimationPlayer
	if animation != null:
		animation.play(animation.get_animation_list()[0])
		animation.seek(0.0, true)
		animation.pause()
	camera.global_position = _ground + Vector3.UP * 0.25
	var head: Vector3 = camera.global_position + Vector3.UP * 0.6 + _forward * 0.12
	camera.look_at(head)
	actor.global_transform = _saved_actor
	actor.look_at(actor.global_position - _forward)
	actor.rotate_object_local(Vector3.RIGHT, deg_to_rad(-55.0))
	var offset: Vector3 = leap.head_position() - actor.global_position
	actor.global_position = head - offset
	_pin_transform = actor.global_transform
	camera.make_current()
	_light.show()
	_refresh_hud()

func advance(delta: float) -> void:
	if not active or _paused:
		return
	var elapsed: float = maxf(delta, 0.0)
	if stage == &"leap":
		leap.advance(elapsed)
		return
	_stage_time += elapsed
	if stage == &"struggle":
		time_left = maxf(0.0, time_left - elapsed)
		actor.global_position = _pin_transform.origin + Vector3.UP * sin(_stage_time * 7.0) * 0.015
		if time_left <= 0.0:
			_begin_bite()
	elif stage == &"push":
		var progress: float = clampf(_stage_time / PUSH_SECONDS, 0.0, 1.0)
		actor.global_transform = _pin_transform.interpolate_with(_push_end, smoothstep(0.0, 1.0, progress))
		if progress >= 1.0:
			_finish(true)
	elif stage == &"bite":
		var progress: float = clampf(_stage_time / BITE_SECONDS, 0.0, 1.0)
		var head_offset: Vector3 = leap.head_position() - actor.global_position
		var bite_position: Vector3 = camera.global_position - camera.global_basis.z * 0.09 - head_offset
		actor.global_position = _pin_transform.origin.lerp(bite_position, smoothstep(0.0, 1.0, progress))
		upper_jaw.position.y = lerpf(0.28, 0.02, progress)
		lower_jaw.position.y = -upper_jaw.position.y
		hud.bite_progress = progress
		if progress >= 1.0:
			_finish(false)
	_refresh_hud()

func handle_input(event: InputEvent) -> bool:
	if not active or _paused or stage != &"struggle" or not event is InputEventKey:
		return false
	var key: InputEventKey = event as InputEventKey
	if key.keycode != KEY_SPACE and key.physical_keycode != KEY_SPACE:
		return false
	if not key.pressed:
		_space_down = false
		return true
	if key.echo or _space_down:
		return true
	_space_down = true
	presses += 1
	if presses >= REQUIRED_PRESSES:
		stage = &"push"
		_stage_time = 0.0
		_pin_transform = actor.global_transform
		_push_end = Transform3D(_saved_actor.basis, _retreat_target())
	_refresh_hud()
	return true

func _begin_bite() -> void:
	stage = &"bite"
	_stage_time = 0.0
	_pin_transform = actor.global_transform
	upper_jaw.show()
	lower_jaw.show()
	if DisplayServer.get_name() != "headless":
		_crunch.play()

func _retreat_target() -> Vector3:
	var desired: Vector3 = _ground + _forward * 3.0
	var from: Vector3 = _ground + Vector3.UP
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, desired + Vector3.UP, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		desired = (hit.position as Vector3) + (hit.normal as Vector3) * 0.6
		desired.y = _ground.y
	var world: Node3D = actor.get("world") as Node3D
	if world != null:
		var route: PackedVector2Array = world.call("route", _ground, desired) as PackedVector2Array
		if not route.is_empty():
			desired = Vector3(route[-1].x, _saved_actor.origin.y, route[-1].y)
	return desired

func _finish(success: bool) -> void:
	var callback: Callable = _won if success else _lost
	_cleanup(not success)
	if callback.is_valid():
		callback.call()

func _refresh_hud() -> void:
	hud.visible = active and not _paused and stage != &"leap"
	hud.stage = stage
	hud.presses = presses
	hud.required = REQUIRED_PRESSES
	hud.remaining = time_left
	hud.queue_redraw()

func set_paused(paused: bool) -> void:
	_paused = paused
	_space_down = false
	_refresh_hud()

func _cleanup(restore_actor: bool = true) -> void:
	active = false
	stage = &""
	leap.cancel()
	_light.hide()
	upper_jaw.hide()
	lower_jaw.hide()
	_crunch.stop()
	hud.hide()
	if is_instance_valid(actor):
		if restore_actor:
			actor.global_transform = _saved_actor
		var animation: AnimationPlayer = actor.get("animation") as AnimationPlayer
		if animation != null and not animation.get_animation_list().is_empty():
			animation.play(animation.get_animation_list()[0])
			animation.seek(0.0, true)
			animation.pause()
			animation.speed_scale = 1.0
	if is_instance_valid(_source) and _source.is_inside_tree():
		_source.make_current()
	if is_instance_valid(_hand):
		_hand.visible = _hand_was_visible
	_won = Callable()
	_lost = Callable()

func _jaw(upper: bool) -> Node3D:
	var jaw: Node3D = Node3D.new()
	camera.add_child(jaw)
	jaw.position = Vector3(0, 0.28 if upper else -0.28, -0.25)
	var bone: StandardMaterial3D = StandardMaterial3D.new()
	bone.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bone.albedo_color = Color("c9b7a4")
	var gum: StandardMaterial3D = StandardMaterial3D.new()
	gum.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gum.albedo_color = Color("53121a")
	var base: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.65, 0.07, 0.07)
	base.mesh = box
	base.material_override = gum
	jaw.add_child(base)
	for index: int in 10:
		var tooth: MeshInstance3D = MeshInstance3D.new()
		var cone: CylinderMesh = CylinderMesh.new()
		cone.top_radius = 0.003
		cone.bottom_radius = 0.022
		cone.height = 0.07 + float(index % 3) * 0.012
		cone.radial_segments = 5
		tooth.mesh = cone
		tooth.material_override = bone
		tooth.position = Vector3((index - 4.5) * 0.059, -0.05 if upper else 0.05, 0.01)
		tooth.rotation.z = PI if upper else 0.0
		jaw.add_child(tooth)
	jaw.hide()
	return jaw

func _exit_tree() -> void:
	if active:
		_cleanup()
