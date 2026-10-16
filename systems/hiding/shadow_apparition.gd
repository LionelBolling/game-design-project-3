class_name ShadowApparition
extends Node3D
const PLAYER_HEIGHT: float = 1.12
## Non-colliding, code-built hallucination. Local front is -Z.
func _ready() -> void:
	scale = Vector3.ONE * (PLAYER_HEIGHT / 3.2)
	var black: StandardMaterial3D = _material(Color("020203"))
	var blood: StandardMaterial3D = _material(Color("b70b19"))
	var teeth: StandardMaterial3D = _material(Color("bfa99b"))
	_ellipsoid(Vector3(0, 1.83, 0), Vector3(0.5, 1.05, 0.23), black)
	_ellipsoid(Vector3(0, 2.85, -0.02), Vector3(0.24, 0.34, 0.19), black)
	for side: float in [-1.0, 1.0]:
		_ellipsoid(Vector3(side * 0.19, 0.67, 0), Vector3(0.105, 0.7, 0.1), black)
		var arm: MeshInstance3D = _ellipsoid(Vector3(side * 0.46, 1.65, 0), Vector3(0.07, 0.92, 0.07), black)
		arm.rotation.z = side * 0.09
		for finger: int in 3:
			_ellipsoid(Vector3(side * 0.51 + (finger - 1) * 0.035, 0.72, -0.02), Vector3(0.014, 0.19, 0.018), black)
	# A wet red crescent with uneven teeth and three hanging blood trails.
	for index: int in 19:
		var x: float = (float(index) / 18.0 - 0.5) * 0.39
		var y: float = 2.72 + pow(absf(x) / 0.195, 1.7) * 0.12
		_ellipsoid(Vector3(x, y, -0.19), Vector3(0.025, 0.035, 0.018), blood)
		if index % 2 == 0:
			_ellipsoid(Vector3(x, y + 0.013, -0.206), Vector3(0.011, 0.017, 0.006), teeth)
	for x: float in [-0.12, 0.01, 0.1]:
		_ellipsoid(Vector3(x, 2.64, -0.185), Vector3(0.009, 0.09, 0.009), blood)
	hide()

func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func _ellipsoid(at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 12
	sphere.rings = 8
	part.mesh = sphere
	part.material_override = material
	part.position = at
	part.scale = dimensions
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(part)
	return part
