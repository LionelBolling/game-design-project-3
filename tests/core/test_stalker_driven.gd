extends GutTest
## The mock's Ronald (scripts/stalker.gd) with the board driving him: his own
## brain (beam freeze, beam pounce, chasing, catching) stays off.


class FakePlayer:
	extends CharacterBody3D
	var control_enabled := true
	var camera := Camera3D.new()
	var lit := true # the flashlight is right on him
	func beam_hits(_point: Vector3) -> bool:
		return lit


class FakeWorld:
	extends Node3D
	const STALKER_SPAWN := Vector3.ZERO
	func route(from: Vector3, to: Vector3) -> PackedVector2Array:
		return PackedVector2Array([Vector2(from.x, from.z), Vector2(to.x, to.z)])


var ronald: Node3D
var player: FakePlayer


func before_each() -> void:
	player = add_child_autofree(FakePlayer.new())
	player.add_child(player.camera)
	player.global_position = Vector3(0.3, 0, 0) # within his catch reach
	ronald = add_child_autofree(Node3D.new())
	ronald.set_script(load("res://scripts/stalker.gd"))
	ronald.set("player", player)
	ronald.set("world", add_child_autofree(FakeWorld.new()))
	ronald.call("awaken")
	ronald.set("grace", 0.0)
	ronald.set_physics_process(false)


func test_driven_he_never_catches_or_freezes_on_his_own() -> void:
	ronald.set("driven", true)
	watch_signals(ronald)
	for i in 70: # 7 s: past the 6 s beam pounce
		ronald.call("_physics_process", 0.1)
	assert_signal_not_emitted(ronald, "caught")
	assert_signal_not_emitted(ronald, "light_attack")
	assert_false(bool(ronald.get("frozen")))


func test_undriven_he_still_catches_on_his_own() -> void:
	player.lit = false # the old brain freezes in the beam
	watch_signals(ronald)
	ronald.call("_physics_process", 0.1)
	assert_signal_emitted(ronald, "caught", "the old brain is still there for Lionel's tests")
