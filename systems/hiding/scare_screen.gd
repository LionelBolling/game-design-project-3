class_name ScareScreen
extends Control
## Screen-space face composition; mouse input passes through the overlay.
const CLOWN: PackedScene = preload("res://Blender models/ps1-clown.glb")
const FLASH_SECONDS: float = 0.28
var words: String = "you better run"
var age: float = 0.0
var remaining: float = 0.0
var reduced_motion: bool = false
var portrait: SubViewport
var _noise: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_portrait()
	hide()

func begin(reduced: bool = false) -> void:
	reduced_motion = reduced
	age = 0.0
	remaining = FLASH_SECONDS
	portrait.render_target_update_mode = SubViewport.UPDATE_ONCE
	show()
	queue_redraw()

func advance(delta: float) -> void:
	if not visible:
		return
	age += maxf(0.0, delta)
	remaining = maxf(0.0, remaining - maxf(0.0, delta))
	if remaining <= 0.0:
		hide()
	queue_redraw()

func _draw() -> void:
	if portrait == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("100407"))
	var side: float = maxf(size.x, size.y)
	var jitter: Vector2 = Vector2.ZERO if reduced_motion else Vector2(sin(age * 57.0) * 9.0, cos(age * 43.0) * 5.0)
	draw_texture_rect(portrait.get_texture(), Rect2((size - Vector2.ONE * side) * 0.5 + jitter, Vector2.ONE * side), false, Color(1.0, 0.72, 0.68))
	_noise.seed = int(age * 24.0) + 440
	for index: int in 110:
		var y: float = _noise.randf_range(0.0, size.y)
		var alpha: float = _noise.randf_range(0.025, 0.13)
		draw_rect(Rect2(0, y, size.x, _noise.randf_range(1.0, 4.0)), Color(0.85, 0.8, 0.8, alpha))
	for index: int in 90:
		var at: Vector2 = Vector2(_noise.randf_range(0.0, size.x), _noise.randf_range(0.0, size.y))
		draw_rect(Rect2(at, Vector2(_noise.randf_range(8.0, 70.0), 2)), Color(0.7, 0.7, 0.7, 0.18))
	var font: Font = ThemeDB.fallback_font
	var font_size: int = maxi(22, int(size.y * 0.075))
	var text_size: Vector2 = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var origin: Vector2 = Vector2((size.x - text_size.x) * 0.5, size.y * 0.84)
	draw_rect(Rect2(Vector2(0, origin.y - font_size), Vector2(size.x, font_size * 1.5)), Color(0.02, 0.0, 0.0, 0.75))
	draw_string(font, origin + Vector2(3, 2), words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("a40810"))
	draw_string(font, origin, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("f4d9d5"))

func _build_portrait() -> void:
	portrait = SubViewport.new()
	portrait.size = Vector2i(512, 512)
	portrait.own_world_3d = true
	portrait.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(portrait)
	var model: Node3D = CLOWN.instantiate() as Node3D
	model.scale = Vector3.ONE * 0.4
	model.rotation.y = PI
	portrait.add_child(model)
	var animation: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	animation.play(animation.get_animation_list()[0])
	animation.advance(0.0)
	animation.pause()
	var skeletons: Array[Node] = model.find_children("*", "Skeleton3D", true, false)
	var skeleton: Skeleton3D = skeletons[0] as Skeleton3D
	skeleton.force_update_all_bone_transforms()
	var head: Vector3 = skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_Head")).origin)
	var camera: Camera3D = Camera3D.new()
	portrait.add_child(camera)
	camera.position = head + Vector3(0, 0.08, -0.6)
	camera.look_at(head + Vector3(0, 0.04, 0))
	camera.near = 0.02
	camera.fov = 60.0
	camera.current = true
	var environment: WorldEnvironment = WorldEnvironment.new()
	var settings: Environment = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("080204")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("bdb0aa")
	settings.ambient_light_energy = 0.5
	environment.environment = settings
	portrait.add_child(environment)
	var light: OmniLight3D = OmniLight3D.new()
	light.position = head + Vector3(0, 0.2, -1.0)
	light.light_color = Color("f3d5c7")
	light.light_energy = 2.0
	light.omni_range = 4.0
	portrait.add_child(light)
