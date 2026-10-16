class_name HidingHud
extends CanvasLayer

var bar: ProgressBar
var message: Label

func _ready() -> void:
	bar = ProgressBar.new()
	bar.position = Vector2(24, 60)
	bar.size = Vector2(300, 24)
	bar.max_value = HideTimer.LIMIT_SECONDS
	bar.show_percentage = false
	add_child(bar)
	message = Label.new()
	message.position = Vector2(24, 24)
	add_child(message)

func refresh(board: Blackboard, timer: HideTimer, nearby: bool) -> void:
	bar.visible = board.hide_state == BoardTypes.Hide.HIDDEN
	bar.value = timer.remaining
	if board.game_state != BoardTypes.Game.PLAYING:
		message.text = "Caught! Press R to restart."
	elif board.location_leaked:
		message.text = "Location revealed! E to leave"
	elif bar.visible:
		message.text = "Hidden: %.1f s remaining | E to leave" % timer.remaining
	elif nearby:
		message.text = "E to hide | Hide budget: %.1f / 7 s" % timer.remaining
	else:
		message.text = "WASD to move | Mouse to look | E to hide | Esc releases mouse"
