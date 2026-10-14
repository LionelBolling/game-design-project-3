extends GutTest
## The sandbox can draw Ronald in every mode.

const Sandbox = preload("res://systems/core/sandbox/sandbox.gd")


func test_the_sandbox_has_a_color_for_every_mode() -> void:
	for mode: int in BoardTypes.Mode.values():
		assert_true(Sandbox.MODE_COLORS.has(mode), "no color for %s" % BoardTypes.Mode.keys()[mode])
