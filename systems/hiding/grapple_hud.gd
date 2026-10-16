class_name GrappleHud
extends Control
var stage: StringName = &""
var presses: int = 0
var required: int = 12
var remaining: float = 4.0
var bite_progress: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var scale_factor: float = size.y / 720.0
	var text_size: int = maxi(20, int(32.0 * scale_factor))
	if stage == &"bite":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.0, 0.0, bite_progress * 0.8))
		return
	var words: String = "MASH SPACE  —  PUSH HIM OFF" if stage == &"struggle" else "GET AWAY!"
	var width: float = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var at: Vector2 = Vector2((size.x - width) * 0.5, size.y * 0.82)
	draw_rect(Rect2(0, at.y - text_size * 1.3, size.x, text_size * 3.6), Color(0.015, 0.0, 0.0, 0.86))
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, Color("f3ded7"))
	if stage == &"struggle":
		var caption: String = "%d / %d presses     %.1f s" % [presses, required, maxf(remaining, 0.0)]
		draw_string(font, Vector2(size.x * 0.36, at.y + text_size * 1.15), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, int(text_size * 0.7), Color("cfaaa1"))
		var bar: Rect2 = Rect2(size.x * 0.24, at.y + text_size * 1.5, size.x * 0.52, 10.0 * scale_factor)
		draw_rect(bar, Color("392024"))
		bar.size.x *= clampf(float(presses) / required, 0.0, 1.0)
		draw_rect(bar, Color("a82b34"))
