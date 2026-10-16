class_name HideSpot
extends Area3D
## Place the area beside furniture; hide_offset marks the player's hiding feet.

enum Kind { TABLE, BALL_PIT, TUBE, BOOTH }
const GROUP: StringName = &"hiding_spots"
@export var spot_id: StringName = &""
@export var spot_type: Kind = Kind.TABLE
@export var hide_offset: Vector3 = Vector3.ZERO
@export var eye_height: float = 0.55
@export var keep_position: bool = false
@export var face_outward: bool = false
@export var outward_yaw: float = PI
@export var display_name: String = "table"
@export var show_marker: bool = false
var marker: Label3D
var markers_enabled: bool = false

func _ready() -> void:
	add_to_group(GROUP)
	if show_marker:
		marker = Label3D.new()
		marker.text = "E / HIDE\n" + display_name.to_upper()
		marker.position = hide_offset + Vector3(0, 1.15, 0)
		marker.font_size = 32
		marker.pixel_size = 0.006
		marker.modulate = Color("e8b64b")
		marker.outline_size = 8
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.no_depth_test = false
		marker.hide()
		add_child(marker)

func _process(_delta: float) -> void:
	if marker == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		marker.hide()
		return
	var distance: float = camera.global_position.distance_to(hiding_position() + Vector3.UP * 0.5)
	marker.visible = markers_enabled and distance > 1.5 and distance < 8.0

func hiding_position() -> Vector3:
	return global_position + global_basis * hide_offset
