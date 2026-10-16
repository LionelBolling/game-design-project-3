extends Node3D

const Geo = preload("res://scripts/geometry.gd")
const BALL_COUNT := 80

var camera: Camera3D
var balls: MultiMesh
var ball_cloud: MultiMeshInstance3D
var cover_ball: MeshInstance3D
var shark: Node3D
var leviathan: Node3D
var mode := ""

func setup(view: Camera3D) -> void:
	camera = view
	var sphere := SphereMesh.new()
	sphere.radius = 0.21
	sphere.height = 0.42
	sphere.radial_segments = 9
	sphere.rings = 5
	var material: StandardMaterial3D = Geo.material(Color.WHITE, 0.05, 0.15)
	material.vertex_color_use_as_albedo = true
	sphere.material = material
	balls = MultiMesh.new()
	balls.transform_format = MultiMesh.TRANSFORM_3D
	balls.use_colors = true
	balls.mesh = sphere
	balls.instance_count = BALL_COUNT
	balls.custom_aabb = AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
	var colors := [Color("b84942"), Color("d2ae4b"), Color("4275b0")]
	for i in BALL_COUNT:
		balls.set_instance_color(i, colors[i % 3])
		balls.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(0, 0, 4)))
	ball_cloud = MultiMeshInstance3D.new()
	ball_cloud.multimesh = balls
	ball_cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera.add_child(ball_cloud)
	ball_cloud.hide()
	var cover_material: StandardMaterial3D = Geo.material(Color("c34b43"), 0.08, 0.2)
	cover_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cover_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cover_ball = Geo.sphere(camera, Vector3(0, 0, 4), 0.55, cover_material)
	cover_ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cover_ball.hide()
	shark = _sea_creature(false)
	leviathan = _sea_creature(true)
	shark.hide()
	leviathan.hide()

func _sea_creature(huge: bool) -> Node3D:
	var creature := Node3D.new()
	creature.name = "Leviathan" if huge else "Shark"
	add_child(creature)
	var skin := Geo.material(Color("0d2732") if huge else Color("456b78"), 0.1, 0.05)
	var underside := Geo.material(Color("273b45") if huge else Color("a1b3b4"), 0.05, 0.04)
	if huge:
		skin.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		underside.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var body := Geo.sphere(creature, Vector3.ZERO, 1.0, skin)
	body.scale = Vector3(2.4, 0.78, 0.7)
	var belly := Geo.sphere(creature, Vector3(-0.35, -0.42, 0), 0.65, underside)
	belly.scale = Vector3(2.1, 0.42, 0.87)
	var nose := Geo.sphere(creature, Vector3(-1.8, -0.1, 0), 0.66, skin)
	nose.scale = Vector3(1.1, 0.76, 0.8)
	var mouth := Geo.sphere(creature, Vector3(-2.25, -0.43, 0), 0.53, Geo.material(Color("080e13")))
	mouth.scale = Vector3(0.54, 0.57, 1.3)
	for side in [-1.0, 1.0]:
		Geo.sphere(creature, Vector3(-1.7, 0.25, side * 0.5), 0.13, Geo.material(Color("bce6e1") if huge else Color("091015"), 0.0, 1.3 if huge else 0.0))
		var fin := Geo.sphere(creature, Vector3(0.1, 0.2, side * 0.84), 0.6, skin)
		fin.scale = Vector3(1.7, 0.18, 0.62)
		fin.rotation.y = side * 0.5
		var tail := Geo.sphere(creature, Vector3(2.35, side * 0.66, 0), 0.58, skin)
		tail.scale = Vector3(0.45, 1.5, 0.27)
		tail.rotation.z = side * 0.4
	var dorsal := Geo.sphere(creature, Vector3(0.15, 0.82, 0), 0.62, skin)
	dorsal.scale = Vector3(0.9, 1.4, 0.24)
	for tooth in 7:
		for side in [-1.0, 1.0]:
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.0
			mesh.bottom_radius = 0.075
			mesh.height = 0.25
			mesh.radial_segments = 3
			Geo.mesh(creature, mesh, Vector3(-2.57 + tooth * 0.08, -0.41, side * (0.08 + tooth * 0.06)), underside)
	if huge:
		creature.scale = Vector3.ONE * 4.5
		creature.rotation.z = -PI / 2
	return creature

func begin(next_mode: String) -> void:
	mode = next_mode
	ball_cloud.visible = next_mode == "depth"
	cover_ball.show()
	shark.visible = next_mode == "maze"
	leviathan.hide()
	cover_ball.position = Vector3(0, -0.1, 4)
	cover_ball.scale = Vector3.ONE * 0.01

func animate(time: float) -> void:
	if mode == "depth":
		var cover := clampf((time - 0.7) / 0.65, 0.0, 1.0)
		var uncover := clampf((time - 1.55) / 0.8, 0.0, 1.0)
		cover_ball.position = Vector3(0, -0.08, lerpf(-2.0, -0.2, cover) + uncover * 2.0)
		cover_ball.scale = Vector3.ONE * lerpf(0.1, 2.3, cover) * (1.0 - uncover * 0.6)
		cover_ball.visible = time > 0.65 and time < 2.35
		for i in BALL_COUNT:
			var angle := float(i) * 2.399963
			var ring := sqrt(float(i) / float(BALL_COUNT))
			var radius := lerpf(2.7, 0.6, minf(1.0, time / 1.1)) + maxf(0.0, time - 1.4) * 1.0
			var offset := Vector3(cos(angle) * ring * radius, sin(angle) * ring * radius - time * 0.22, -0.65 - float(i % 5) * 0.2)
			balls.set_instance_transform(i, Transform3D(Basis.IDENTITY, offset))
	elif mode == "maze":
		ball_cloud.hide()
		# The shark can reach the mouth, but its shoulders cannot enter the tube.
		var approach := clampf(time / 1.25, 0.0, 1.0)
		var recoil := clampf((time - 1.35) / 0.7, 0.0, 1.0)
		var escape := clampf((time - 2.1) / 0.85, 0.0, 1.0)
		shark.position = Vector3(lerpf(-4.5, -10.1, approach) + recoil * 1.3, -51.5 + escape * 13.0, -17.0)
		shark.rotation.y = 0.08 * sin(time * 10.0)
		shark.visible = time < 2.95
		# The larger silhouette breaches upward 1.5 seconds after the shark leaves.
		leviathan.visible = time >= 4.45 and time < 5.65
		leviathan.position = Vector3(5.0, lerpf(-76.0, -54.0, clampf((time - 4.45) / 0.8, 0.0, 1.0)), -17.0)
		var hit := clampf((time - 5.0) / 0.6, 0.0, 1.0)
		cover_ball.position = Vector3(0, -0.08, lerpf(-5.0, -0.15, hit) + maxf(0.0, time - 5.8) * 2.0)
		cover_ball.scale = Vector3.ONE * lerpf(0.2, 2.6, hit)
		cover_ball.visible = time >= 5.0 and time < 6.3

func end() -> void:
	mode = ""
	ball_cloud.hide()
	cover_ball.hide()
	shark.hide()
	leviathan.hide()
