class_name HideTimer
extends RefCounted
## Shared hiding budget. Current-visit time is separate from remaining budget.

const LIMIT_SECONDS: float = 7.0
const REFILL_PER_SECOND: float = 0.5

var remaining: float = LIMIT_SECONDS
var hide_time: float = 0.0
var spot_id: StringName = &""


func enter(new_spot: StringName) -> void:
	if new_spot == &"" or spot_id != &"":
		return
	spot_id = new_spot
	hide_time = 0.0


func leave() -> void:
	spot_id = &""
	hide_time = 0.0


func advance(delta: float) -> void:
	var elapsed: float = maxf(delta, 0.0)
	if spot_id != &"":
		hide_time += elapsed
		remaining = maxf(0.0, remaining - elapsed)
	else:
		remaining = minf(LIMIT_SECONDS, remaining + elapsed * REFILL_PER_SECOND)


func leaked() -> bool:
	return spot_id != &"" and remaining <= 0.0
