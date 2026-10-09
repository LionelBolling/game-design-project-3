class_name BoardOverlay
extends CanvasLayer
## Live view of every blackboard value, grouped by the system that writes it.
## F2 shows or hides it. Add it to any scene that has a Director.


const SYSTEM_TITLES: Dictionary[StringName, String] = {
	&"hiding": "HIDING (Lionel)",
	&"senses": "SENSES (Aiden)",
	&"ruleset": "RULESET (Rickey)",
	&"roaming": "ROAMING (Naomi)",
}

@export var director: Director

var _label := Label.new()


func _ready() -> void:
	layer = 10
	_label.position = Vector2(16, 16)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(_label)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F2:
		_label.visible = not _label.visible


func _process(_delta: float) -> void:
	if director == null or not _label.visible:
		return
	var lines: PackedStringArray = []
	var last_owner: StringName = &""
	var values := director.board.snapshot()
	for key: StringName in values:
		var key_owner: StringName = Blackboard.OWNERS[key]
		if key_owner != last_owner:
			if not lines.is_empty():
				lines.append("")
			lines.append(SYSTEM_TITLES[key_owner])
			last_owner = key_owner
		lines.append("  %s: %s" % [key, format_value(key, values[key])])
	_label.text = "\n".join(lines)


## Board values as readable text: enum names, rounded numbers.
static func format_value(key: StringName, value: Variant) -> String:
	match key:
		&"hide_state":
			return BoardTypes.Hide.keys()[value]
		&"detection":
			return BoardTypes.Detect.keys()[value]
		&"ronald_mode":
			return BoardTypes.Mode.keys()[value]
		&"game_state":
			return BoardTypes.Game.keys()[value]
	if value is Vector3:
		return "(%.1f, %.1f, %.1f)" % [value.x, value.y, value.z]
	if value is float:
		return "%.2f" % value
	return str(value)
