class_name ChaseStatic
extends Control
## Translucent interference: the level remains visible during a chase.
var clock: float = 0.0
var reduced_motion: bool = false
var _noise: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func advance(delta: float) -> void:
	clock += maxf(delta, 0.0)
	if visible:
		queue_redraw()

func _draw() -> void:
	_noise.seed = 440 + (0 if reduced_motion else int(clock * 18.0))
	for index: int in 100:
		var y: float = _noise.randf_range(0.0, size.y)
		draw_rect(Rect2(0, y, size.x, _noise.randf_range(1.0, 3.0)), Color(0.7, 0.75, 0.75, _noise.randf_range(0.03, 0.12)))
	for index: int in 230:
		var at: Vector2 = Vector2(_noise.randf_range(0, size.x), _noise.randf_range(0, size.y))
		draw_rect(Rect2(at, Vector2(_noise.randf_range(2, 18), 2)), Color(0.85, 0.85, 0.85, 0.16))
