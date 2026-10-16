extends Node3D
## Local integration scene. Other systems remain the published stubs.

var director: Director
var enemy: MeshInstance3D
var ambience: AudioStreamPlayer
var hiding: HidingSystem

func _ready() -> void:
	_box(Vector3(0, -0.15, 0), Vector3(24, 0.3, 24), Color("242522"), true)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -20, 0)
	add_child(light)
	var environment: WorldEnvironment = WorldEnvironment.new()
	var settings: Environment = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("242522")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("C9C1A5")
	settings.ambient_light_energy = 0.5
	environment.environment = settings
	add_child(environment)
	_make_spot(Vector3(-3, 0, 1), &"table", HideSpot.Kind.TABLE, 0.45)
	director = Director.new()
	hiding = HidingSystem.new()
	director.add_child(hiding)
	director.add_child(SensesStub.new())
	director.add_child(RulesetStub.new())
	director.add_child(RoamingStub.new())
	add_child(director)
	enemy = _box(Vector3.ZERO, Vector3(0.6, 1.8, 0.6), Color("731F24"), false)
	# A dedicated local bus affects only this scene's test ambience.
	if AudioServer.get_bus_index(&"HidingTestAmbience") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, &"HidingTestAmbience")
		AudioServer.add_bus_effect(AudioServer.bus_count - 1, AudioEffectLowPassFilter.new())
	ambience = AudioStreamPlayer.new()
	ambience.bus = &"HidingTestAmbience"
	ambience.stream = load("res://audio/room.wav") as AudioStream
	ambience.volume_db = -12.0
	add_child(ambience)

func _process(_delta: float) -> void:
	enemy.position = director.board.enemy_position + Vector3(0, 0.9, 0)
	var bus: int = AudioServer.get_bus_index(&"HidingTestAmbience")
	var muffled: bool = director.board.hide_spot == &"ball_pit"
	AudioServer.set_bus_effect_enabled(bus, 0, muffled)
	if Input.is_physical_key_pressed(KEY_R):
		get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventKey) and event.is_pressed() and not ambience.playing:
		ambience.play()

func _make_spot(at: Vector3, id: StringName, kind: HideSpot.Kind, eye: float) -> void:
	var packed: PackedScene = load("res://systems/hiding/hide_spot.tscn") as PackedScene
	var spot: HideSpot = packed.instantiate() as HideSpot
	spot.position = at
	spot.spot_id = id
	spot.spot_type = kind
	spot.eye_height = eye
	spot.hide_offset = Vector3(0, 0, -0.5)
	add_child(spot)
	var label: Label3D = Label3D.new()
	label.text = String(id).replace("_", " ")
	label.position = at + Vector3(0, 1.8, 0)
	label.font_size = 40
	add_child(label)
	if kind == HideSpot.Kind.TABLE:
		_box(at + Vector3(0, 0.85, -0.5), Vector3(2, 0.12, 1.8), Color("B39839"), true)
		for x: float in [-0.85, 0.85]:
			for z: float in [-1.2, 0.2]:
				_box(at + Vector3(x, 0.4, z), Vector3(0.12, 0.8, 0.12), Color("731F24"), true)
	elif kind == HideSpot.Kind.BOOTH:
		_box(at + Vector3(0, 0.6, -1.3), Vector3(2, 1.2, 0.2), Color("731F24"), true)
		_box(at + Vector3(0, 0.35, -0.6), Vector3(2, 0.25, 1), Color("731F24"), false)
	elif kind == HideSpot.Kind.TUBE:
		for x: float in [-0.7, 0.7]:
			_box(at + Vector3(x, 0.55, -0.6), Vector3(0.15, 1.1, 2), Color("B39839"), true)
		_box(at + Vector3(0, 1.05, -0.6), Vector3(1.5, 0.1, 2), Color("731F24"), true)
	else:
		for x: float in [-1.0, 1.0]:
			_box(at + Vector3(x, 0.3, -0.5), Vector3(0.1, 0.6, 2), Color("B39839"), true)
		for index: int in range(40):
			var ball: MeshInstance3D = MeshInstance3D.new()
			var sphere: SphereMesh = SphereMesh.new()
			sphere.radius = 0.13
			sphere.height = 0.26
			ball.mesh = sphere
			ball.position = at + Vector3(float(index % 8) * 0.23 - 0.8, 0.15, float(index / 8) * 0.28 - 1.1)
			var material: StandardMaterial3D = StandardMaterial3D.new()
			material.albedo_color = Color("B39839") if index % 2 == 0 else Color("731F24")
			ball.material_override = material
			add_child(ball)

func _box(at: Vector3, size: Vector3, color: Color, solid: bool) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	add_child(mesh)
	if solid:
		var body: StaticBody3D = StaticBody3D.new()
		var collision: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		mesh.add_child(body)
	return mesh
