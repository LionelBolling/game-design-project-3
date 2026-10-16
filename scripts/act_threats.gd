extends RefCounted

class Shark:
	extends RefCounted
	var elapsed := 0.0
	var pressure := 0.0
	var stare_time := 0.0
	var hits := 0
	var circling := false
	var bumping := false
	var aggressive := false
	var dead := false

	func advance(delta: float, flashlight: bool, watching: bool) -> void:
		elapsed += delta
		pressure += delta * (2.0 if flashlight else 1.0)
		circling = pressure >= 5.0
		bumping = pressure >= 20.0
		stare_time = stare_time + delta if watching and circling else 0.0
		aggressive = aggressive or pressure >= 60.0 or stare_time >= 4.0

	func bite() -> void:
		hits += 1
		dead = hits >= 2

class Centipede:
	extends RefCounted
	var elapsed := 0.0
	var activation_delay := 60.0
	var active := false
	var stare_time := 0.0

	func advance(delta: float) -> void:
		elapsed += delta
		active = elapsed >= activation_delay

	func reset_after_death() -> void:
		elapsed = 0.0
		activation_delay = 30.0
		active = false
		stare_time = 0.0
