class_name CatchCutscene
extends Node3D
## Animate the actual spawned actor in the diner, never a GUI portrait.
const JUMP_SECONDS: float = 0.55
const HOLD_SECONDS: float = 0.75
var hold_seconds: float = HOLD_SECONDS
var active: bool = false
var camera: Camera3D
var actor: Node3D
var _original_camera: Camera3D
var _saved_actor: Transform3D
var _start: Vector3
var _end: Vector3
var _head_offset: Vector3
var _elapsed: float = 0.0
var _finished: Callable
var _light: OmniLight3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	camera = Camera3D.new()
	camera.near = 0.015
	camera.fov = 70.0
	add_child(camera)
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 0.15, -0.05)
	_light.light_color = Color("dfc6be")
	_light.light_energy = 1.3
	_light.omni_range = 5.0
	_light.hide()
	camera.add_child(_light)

func _process(delta: float) -> void:
	advance(delta)

func start(source: Camera3D, ronald: Node3D, completed: Callable) -> void:
	if active:
		return
	_original_camera = source
	actor = ronald
	_saved_actor = actor.global_transform
	_finished = completed
	_elapsed = 0.0
	active = true
	actor.show()
	var direction: Vector3 = source.global_position - actor.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		direction = source.global_basis.z
		direction.y = 0.0
	direction = direction.normalized()
	actor.look_at(actor.global_position + direction)
	var animation: AnimationPlayer = actor.get("animation") as AnimationPlayer
	if animation != null:
		animation.seek(0.0, true)
		animation.pause()
	var head: Vector3 = head_position()
	camera.global_position = head + direction * 2.6 + Vector3.UP * 0.08
	camera.look_at(head)
	_reach_toward_camera()
	_head_offset = head_position() - actor.global_position
	_start = actor.global_position
	_end = camera.global_position - camera.global_basis.z * 0.34 - _head_offset
	camera.make_current()
	_light.show()

func advance(delta: float) -> void:
	if not active:
		return
	_elapsed += maxf(0.0, delta)
	var progress: float = clampf(_elapsed / JUMP_SECONDS, 0.0, 1.0)
	var travel: float = progress * progress * (3.0 - 2.0 * progress)
	actor.global_position = _start.lerp(_end, travel) + Vector3.UP * sin(progress * PI) * 0.65
	if _elapsed >= JUMP_SECONDS + hold_seconds:
		var callback: Callable = _finished
		cancel()
		if callback.is_valid():
			callback.call()

func head_position() -> Vector3:
	var skeleton: Skeleton3D = actor.get("skeleton") as Skeleton3D
	if skeleton == null:
		return actor.global_position + Vector3.UP * 1.7
	skeleton.force_update_all_bone_transforms()
	return skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_Head")).origin)

func _reach_toward_camera() -> void:
	var skeleton: Skeleton3D = actor.get("skeleton") as Skeleton3D
	if skeleton == null:
		return
	for title: String in ["mixamorig_LeftArm", "mixamorig_RightArm", "mixamorig_LeftForeArm", "mixamorig_RightForeArm"]:
		var index: int = skeleton.find_bone(title)
		if index < 0:
			continue
		skeleton.force_update_all_bone_transforms()
		var parent: int = skeleton.get_bone_parent(index)
		var origin: Vector3 = skeleton.get_bone_global_pose(index).origin
		var toward_lens: Vector3 = skeleton.to_local(camera.global_position) - origin
		var desired: Vector3 = (skeleton.get_bone_global_pose(parent).basis.inverse() * toward_lens).normalized()
		var pose: Basis = Basis(skeleton.get_bone_pose_rotation(index))
		skeleton.set_bone_pose_rotation(index, Quaternion(pose.y.normalized(), desired) * pose.get_rotation_quaternion())

func cancel(restore_view: bool = true) -> void:
	if not active:
		return
	active = false
	_finished = Callable()
	_light.hide()
	if is_instance_valid(actor):
		actor.global_transform = _saved_actor
	if restore_view and is_instance_valid(_original_camera) and _original_camera.is_inside_tree():
		_original_camera.make_current()

func _exit_tree() -> void:
	cancel(false)
