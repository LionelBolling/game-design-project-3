extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const PlayerScript = preload("res://scripts/player.gd")
const WorldScript = preload("res://scripts/world.gd")
const HUDScript = preload("res://scripts/hud.gd")
const StalkerScript = preload("res://scripts/stalker.gd")
const DepthScript = preload("res://scripts/ball_depth.gd")
const MazeScript = preload("res://scripts/tube_maze.gd")
const TransitionScript = preload("res://scripts/transition_fx.gd")
const CentipedeScript = preload("res://scripts/maze_centipede.gd")

var player: CharacterBody3D
var world: Node3D
var hud: Control
var stalker: Node3D
var phase := "home"
var intro_time := 0.0
var elapsed := 0.0
var fuses := 0
var spare_cells := 2
var max_spare_cells: int = 2
var power_on := false
## The player opened the powered front door. Hiding writes it to the board
## (player_at_exit) and the Ruleset ends the run.
var at_exit := false
var objective := "Find the three emergency fuses"
var prompt := ""
var message := ""
var message_time := 0.0
var show_performance := false
var low_quality := false
var items: Array[Dictionary] = []
var current_item := -1
var interaction_clock := 0.0
var sounds: Dictionary = {}
var breaker_lamp: MeshInstance3D
var intro_clicked := false
var ambient: AudioStreamPlayer
var nightmare_ambient: AudioStreamPlayer
var loading_to := ""
var loading_time := 0.0
var depth_loops := 0
var maze_kind := ""
var maze_color := ""
var transition_fx: Node3D
var loading_origin := Vector3.ZERO
var loading_swapped := false
var loading_sound_played := false
var centipede: Node3D
var maze_hidden := false
var maze_deaths := 0
var maze_dying := false
var maze_death_time := 0.0
var hiding: HidingSystem
var hiding_director: Director
var ruleset: RulesetSystem
var _hiding_audio_bus: int = -1
var horror_feedback: HorrorFeedback
var horror_events: HorrorEvents
var timeout_scene: TimeoutCutscene
var catch_scene: CatchCutscene
var grapple_scene: GrappleCutscene

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_inputs()
	_environment()
	world = Node3D.new()
	world.set_script(WorldScript)
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = world.SPAWN
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	transition_fx = Node3D.new()
	transition_fx.set_script(TransitionScript)
	add_child(transition_fx)
	transition_fx.setup(player.camera)
	stalker = Node3D.new()
	stalker.set_script(StalkerScript)
	stalker.player = player
	stalker.world = world
	stalker.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(stalker)
	stalker.caught.connect(func(): finish(false))
	stalker.light_attack.connect(_begin_grapple)
	_items()
	max_spare_cells = spare_cells + world.CELL_POSITIONS.size()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Control.new()
	hud.set_script(HUDScript)
	hud.game = self
	canvas.add_child(hud)
	hud.lens_material.set_shader_parameter("darkness", 0.0)
	_audio()
	_setup_hiding()
	horror_feedback = HorrorFeedback.new()
	add_child(horror_feedback)
	horror_events = HorrorEvents.new()
	add_child(horror_events)
	timeout_scene = TimeoutCutscene.new()
	add_child(timeout_scene)
	timeout_scene.configure(player, stalker)
	catch_scene = CatchCutscene.new()
	add_child(catch_scene)
	grapple_scene = GrappleCutscene.new()
	add_child(grapple_scene)
	horror_feedback.voice_managed_by_cutscene = true
	player.camera.make_current()
	_show_home_view()
	hud.show_menu("home")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("RONALD'S: %d source meshes -> %d static batches; %d Blender balls -> 1 MultiMesh." % [world.source_mesh_count, world.batch_count, world.ball_count])

func _setup_hiding() -> void:
	hiding_director = Director.new()
	hiding_director.name = "HidingDirector"
	hiding_director.process_mode = Node.PROCESS_MODE_PAUSABLE
	var legacy_hiding := LegacyHiding.new()
	legacy_hiding.game = self
	hiding = legacy_hiding
	hiding.external_body = true
	hiding.keyboard = false
	hiding.body = player
	hiding.camera = player.get("camera") as Camera3D
	hiding_director.add_child(hiding)
	# The Ruleset (Rickey) decides what Ronald does. Senses and Roaming are
	# stand-ins built on this mock (scripts/legacy_*.gd) until Aiden's and
	# Naomi's systems replace them.
	var senses := LegacySenses.new()
	senses.stalker = stalker
	hiding_director.add_child(senses)
	ruleset = RulesetSystem.new()
	ruleset.end_screens = false # this game draws its own
	hiding_director.add_child(ruleset)
	var roaming := LegacyRoaming.new()
	roaming.stalker = stalker
	roaming.world = world
	hiding_director.add_child(roaming)
	add_child(hiding_director)
	# Lionel's timeout cutscene voices "I see you" and the catch cutscene
	# screams, so the rules' placeholder whisper and scream stay silent here.
	ruleset.cue_player.sounds[&"whisper"] = null
	ruleset.cue_player.sounds[&"scream"] = null
	hiding_director.set_physics_process(false)
	hiding.hud.message.position = Vector2(40, 570)
	hiding.hud.bar.position = Vector2(40, 606)
	hiding.hud.hide()
	if AudioServer.get_bus_index(&"MainHidingAmbience") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, &"MainHidingAmbience")
		AudioServer.add_bus_effect(AudioServer.bus_count - 1, AudioEffectLowPassFilter.new())
	_hiding_audio_bus = AudioServer.get_bus_index(&"MainHidingAmbience")
	AudioServer.set_bus_effect_enabled(_hiding_audio_bus, 0, false)
	ambient.bus = &"MainHidingAmbience"
	if nightmare_ambient != null:
		nightmare_ambient.bus = &"MainHidingAmbience"
	for fitting: Dictionary in world.get("appliance_layout"):
		if fitting.asset == "Asset_Table":
			_add_hiding_spot(fitting.position + Vector3(0, 0.12, 0), HideSpot.Kind.TABLE, Vector3(4.0, 1.8, 4.0), 0.38)
		elif fitting.asset == "Asset_Booth":
			_add_hiding_spot(fitting.position + Vector3(0, 0.12, 0), HideSpot.Kind.TABLE, Vector3(4.8, 1.8, 4.0), 0.38, false, "booth table", Vector3(0.25, 0, -0.57), 0.0)
		elif fitting.asset == "Asset_AssemblyTable":
			# These are solid cabinets; hide behind their rear edge, not inside.
			_add_hiding_spot(fitting.position + Vector3(0, 0.12, 1.35), HideSpot.Kind.TABLE, Vector3(5.0, 1.8, 2.0), 0.38, false, "prep counter", Vector3.ZERO)

func _add_hiding_spot(at: Vector3, kind: HideSpot.Kind, size: Vector3, eye: float, keep: bool = false, label: String = "dining table", offset: Vector3 = Vector3(0, 0, 0.57), yaw: float = PI) -> void:
	var spot: HideSpot = HideSpot.new()
	spot.position = at
	spot.spot_id = StringName("main_%s_%s" % [kind, at])
	spot.spot_type = kind
	spot.eye_height = eye
	spot.keep_position = keep
	spot.display_name = label
	spot.show_marker = true
	spot.outward_yaw = yaw
	if kind == HideSpot.Kind.TABLE:
		# The imported table has a central pedestal. Keep the eyes and beam
		# outside it, beneath the 0.715 m tabletop, facing into the room.
		spot.hide_offset = offset
		spot.face_outward = true
	spot.collision_layer = 0
	spot.collision_mask = 2 # The existing main player uses layer 2.
	var collider: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	collider.position.y = size.y * 0.5
	spot.add_child(collider)
	add_child(spot)

func _physics_process(delta: float) -> void:
	for node: Node in get_tree().get_nodes_in_group(HideSpot.GROUP):
		(node as HideSpot).markers_enabled = phase == "play" and not get_tree().paused and not timeout_scene.camera_locked and not player.hiding_locked
	if phase == "play" and not get_tree().paused:
		hiding_director.step(delta)
		var board: Blackboard = hiding_director.board
		match board.game_state:
			BoardTypes.Game.CAUGHT:
				finish(false)
				return
			BoardTypes.Game.ESCAPED:
				finish(true)
				return
		# Asleep, Ronald can't come for a leaked spot, so no cutaway either.
		timeout_scene.tick(board.location_leaked and board.ronald_mode != BoardTypes.Mode.DORMANT, delta)
		var spot: HideSpot = hiding._spot
		AudioServer.set_bus_effect_enabled(_hiding_audio_bus, 0, spot != null and spot.spot_type == HideSpot.Kind.BALL_PIT)

func _bind_inputs() -> void:
	var bindings := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "sprint": KEY_SHIFT, "jump": KEY_SPACE, "swim_down": KEY_CTRL, "flashlight": KEY_F, "interact": KEY_E, "reload_cell": KEY_R}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = bindings[action]
			InputMap.action_add_event(action, event)

func _environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("030609")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("788795")
	environment.ambient_light_energy = 0.08
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("111b20")
	environment.fog_light_energy = 0.2
	environment.fog_density = 0.008
	var node := WorldEnvironment.new()
	node.environment = environment
	add_child(node)

func _items() -> void:
	var brass := Geo.material(Color("bea56e"), 0.6)
	var fuse_glow := Geo.material(Color("90cda0"), 0.0, 0.45)
	for pos in world.FUSE_POSITIONS:
		var item := Node3D.new()
		item.position = pos
		add_child(item)
		var fuse := Geo.cylinder(item, Vector3.ZERO, 0.055, 0.28, fuse_glow)
		fuse.rotation.z = PI / 2
		for x in [-0.12, 0.12]:
			var cap := Geo.cylinder(item, Vector3(x, 0, 0), 0.059, 0.06, brass)
			cap.rotation.z = PI / 2
		var glow := OmniLight3D.new()
		glow.position = Vector3(0, 0.1, 0)
		glow.light_color = Color("71d997")
		glow.light_energy = 0.28
		glow.omni_range = 1.15
		glow.shadow_enabled = false
		item.add_child(glow)
		items.append({"node": item, "kind": "fuse", "label": "E  /  Take emergency fuse", "taken": false})
	for pos in world.CELL_POSITIONS:
		var cell := Node3D.new()
		cell.position = pos
		add_child(cell)
		Geo.box(cell, Vector3.ZERO, Vector3(0.18, 0.1, 0.12), Geo.material(Color("899d7b"), 0.3, 0.15))
		items.append({"node": cell, "kind": "cell", "label": "E  /  Take spare battery", "taken": false})
	var breaker := Node3D.new()
	breaker.position = world.BREAKER_POSITION
	breaker.rotation.y = -PI / 2
	add_child(breaker)
	Geo.box(breaker, Vector3.ZERO, Vector3(0.75, 0.95, 0.18), Geo.material(Color("3e514f"), 0.5))
	Geo.box(breaker, Vector3(0, -0.1, 0.17), Vector3(0.09, 0.3, 0.09), brass)
	breaker_lamp = Geo.sphere(breaker, Vector3(0.22, 0.25, 0.13), 0.04, Geo.material(Color("ad5840"), 0, 1))
	Geo.label(breaker, "EMERGENCY\nPOWER", Vector3(0, 0.67, 0.13), 20, Color("b9c4b8"))
	items.append({"node": breaker, "kind": "breaker", "label": "E  /  Restore emergency power", "taken": false})
	var exit_marker := Node3D.new()
	exit_marker.position = world.EXIT_POSITION
	add_child(exit_marker)
	items.append({"node": exit_marker, "kind": "exit", "label": "E  /  Open front door", "taken": false})

func _audio() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(0.8))
	for key in ["pickup", "sting", "power", "balls_wade", "shark_swim", "shark_bite", "leviathan_rise", "centipede_legs", "centipede_attack"]:
		var audio := AudioStreamPlayer.new()
		audio.stream = load("res://audio/%s.wav" % key)
		audio.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(audio)
		sounds[key] = audio
	ambient = AudioStreamPlayer.new()
	var stream := load("res://audio/background soundtrack/mcdonald_3min_slow_normal_breathing_more_pitch_variance.mp3") as AudioStreamMP3
	stream.loop = true
	ambient.stream = stream
	ambient.volume_db = -9
	ambient.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(ambient)
	if DisplayServer.get_name() != "headless":
		ambient.play()
	var nightmare_stream := load("res://audio/nightmare_loop.wav") as AudioStreamWAV
	if nightmare_stream == null:
		push_error("The nightmare ambience could not be loaded.")
		return
	nightmare_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	nightmare_ambient = AudioStreamPlayer.new()
	nightmare_ambient.name = "NightmareAmbience"
	nightmare_ambient.stream = nightmare_stream
	nightmare_ambient.volume_db = -20
	nightmare_ambient.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(nightmare_ambient)
	if DisplayServer.get_name() != "headless":
		nightmare_ambient.play()

func sound(key: String, pitch: float = 1.0) -> void:
	# The dummy headless audio driver cannot consume playback buffers.
	if sounds.has(key) and DisplayServer.get_name() != "headless":
		sounds[key].pitch_scale = pitch
		sounds[key].play()

func say(words: String, duration: float = 4.0) -> void:
	message = words
	message_time = duration

func _show_home_view() -> void:
	player.control_enabled = false
	player.position = Vector3(-45, 0, 0)
	player.rotation = Vector3(0, -PI / 2, 0)
	player.camera.position = Vector3(0, 2.7, 0)
	player.camera.rotation = Vector3.ZERO
	player.hand.hide()
	player.lamp.hide()
	player.spill.hide()

func start_game() -> void:
	if phase != "home":
		return
	phase = "intro"
	intro_time = 0.0
	intro_clicked = false
	player.position = world.SPAWN
	player.rotation = Vector3(0, PI, 0)
	player.velocity = Vector3.ZERO
	player.camera.position = Vector3(0, 0.25, 0)
	player.camera.rotation_degrees = Vector3(-20, 0, -12)
	player.hand.show()
	player.begin_intro()
	hud.lens_material.set_shader_parameter("darkness", 1.0)
	hud.show_menu("")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	say("Cold plastic. Stale air. Where is everyone?", 4.3)

func _process(delta: float) -> void:
	if hiding != null:
		hiding.hud.visible = phase == "play" and not get_tree().paused
	if get_tree().paused:
		return
	message_time = maxf(0, message_time - delta)
	if phase == "intro":
		intro_time += delta
		var darkness := 1.0
		if intro_time > 0.5:
			darkness = clampf(1.0 - (intro_time - 0.5) / 1.4, 0, 1)
		if intro_time > 2.2 and intro_time < 3.1:
			darkness = sin((intro_time - 2.2) / 0.9 * PI) * 0.85
		hud.lens_material.set_shader_parameter("darkness", darkness)
		if intro_time >= 4.5 and intro_time < 4.5 + delta:
			say("My flashlight. Still in my pocket.", 2.7)
		if intro_time >= 6.55 and not intro_clicked:
			intro_clicked = true
			player.set_flashlight(true)
		if intro_time >= 8.4:
			finish_intro()
	elif phase == "play":
		elapsed += delta
		interaction_clock -= delta
		if interaction_clock <= 0:
			interaction_clock = 0.1
			_find_interaction()
		var distance: float = player.global_position.distance_to(stalker.global_position)
		hud.lens_material.set_shader_parameter("danger", clampf(1.0 - distance / 5.0, 0, 1) if stalker.active else 0.0)
		if player.global_position.y < -5:
			player.position = world.SPAWN
		if power_on and absf(player.position.x) < 4.0 and player.position.z < -9.0 and player.position.z > -18.0 and player.position.y < 1.1:
			_start_loading("depth")
	elif phase == "loading":
		loading_time += delta
		_animate_transition()
		if loading_to == "maze" and loading_time >= 4.45 and not loading_sound_played:
			loading_sound_played = true
			sound("leviathan_rise")
		if loading_to == "depth" and loading_time >= 1.35 and not loading_swapped:
			_swap_to_depth()
		if loading_to == "maze" and loading_time >= 5.55 and not loading_swapped:
			_swap_to_maze()
		if loading_time >= (2.6 if loading_to == "depth" else 7.7):
			_finish_loading()
	elif phase == "depth":
		elapsed += delta
		if player.position.y < -56.0:
			depth_loops += 1
			player.position.y = -0.8
			player.velocity.y = 0.0
			say("The balls fold back above you. Find the green light.", 4)
		elif player.position.y > -0.05:
			depth_loops += 1
			player.position.y = -55.4
			player.velocity.y = 0.0
			say("The top becomes the bottom. The green light grows brighter.", 4)
		if player.position.y < -49.8 and player.position.y > -55.5 and player.position.x < -12.1 and absf(player.position.z + 17.0) < 2.2:
			_start_loading("maze")
	elif phase == "maze":
		if maze_dying:
			maze_death_time += delta
			if maze_death_time >= 0.9:
				restart_maze()
			return
		elapsed += delta
		interaction_clock -= delta
		if interaction_clock <= 0:
			interaction_clock = 0.1
			_find_maze_interaction()
		if player.position.y < -4.0:
			player.position = MazeScript.SPAWN
			player.velocity = Vector3.ZERO

func finish_intro() -> void:
	phase = "play"
	player.finish_intro()
	hud.lens_material.set_shader_parameter("darkness", 0.0)
	say("Find three fuses. Restore the breaker.", 6.0)

func _start_loading(destination: String) -> void:
	if phase == "loading":
		return
	loading_to = destination
	loading_time = 0.0
	loading_swapped = false
	loading_sound_played = false
	loading_origin = player.position
	phase = "loading"
	player.control_enabled = false
	player.velocity = Vector3.ZERO
	player.collision_mask = 0
	prompt = ""
	message_time = 0
	transition_fx.begin(destination)
	if destination == "depth":
		ambient.stop()
		nightmare_ambient.stop()
	if destination == "maze":
		sound("sting")
	hud.queue_redraw()

func skip_to_depth() -> void:
	get_tree().paused = false
	hud.show_menu("")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	fuses = 3
	power_on = true
	if world.has_method("set_powered"):
		world.set_powered(true)
	player.position = Vector3(0, 0.1, -13.2)
	player.camera.position = Vector3(0, 0.98, 0)
	player.camera.rotation = Vector3.ZERO
	player.pitch = 0.0
	player.hand.show()
	player.set_flashlight(true)
	_start_loading("depth")

func _animate_transition() -> void:
	transition_fx.animate(loading_time)
	if loading_to == "depth":
		if not loading_swapped:
			player.position.y = lerpf(loading_origin.y, -1.3, clampf(loading_time / 1.35, 0.0, 1.0))
		else:
			player.position.y = lerpf(-1.3, -3.4, clampf((loading_time - 1.35) / 1.25, 0.0, 1.0))
		player.pitch = lerpf(0.0, -0.38, sin(clampf(loading_time / 2.6, 0.0, 1.0) * PI))
		player.camera.rotation.x = player.pitch
	else:
		if not loading_swapped:
			var face_out := clampf(loading_time / 0.4, 0.0, 1.0)
			player.rotation.y = lerp_angle(player.rotation.y, -PI / 2, face_out)
			player.pitch = lerpf(player.pitch, 0.1 if loading_time < 4.3 else 0.45, 0.1)
			player.camera.rotation.x = player.pitch
			if loading_time >= 5.0:
				player.position.x = lerpf(loading_origin.x, loading_origin.x - 0.8, clampf((loading_time - 5.0) / 0.55, 0.0, 1.0))
		else:
			var falling := clampf((loading_time - 5.55) / 0.85, 0.0, 1.0)
			player.position.y = lerpf(MazeScript.UPPER_ENTRY.y + 3.65, MazeScript.UPPER_ENTRY.y, falling)
			if loading_time < 6.4:
				player.camera.position.y = lerpf(0.98, 0.35, clampf((loading_time - 6.05) / 0.35, 0.0, 1.0))
				player.pitch = lerpf(0.3, 0.52, falling)
				player.camera.rotation.z = lerpf(0.0, -0.24, clampf((loading_time - 6.05) / 0.35, 0.0, 1.0))
			else:
				var standing := smoothstep(0.0, 1.0, clampf((loading_time - 6.4) / 1.3, 0.0, 1.0))
				player.camera.position.y = lerpf(0.35, 0.98, standing)
				player.pitch = lerpf(0.52, 0.0, standing)
				player.camera.rotation.z = lerpf(-0.24, 0.0, standing)
			player.camera.rotation.x = player.pitch

func _swap_to_depth() -> void:
	loading_swapped = true
	world.queue_free()
	stalker.active = false
	stalker.hide()
	for item in items:
		(item.node as Node3D).hide()
	var depth := Node3D.new()
	depth.set_script(DepthScript)
	add_child(depth)
	world = depth
	player.position = Vector3(0, -1.3, -13.2)
	player.rotation.y = PI / 2
	player.velocity = Vector3.ZERO

func _swap_to_maze() -> void:
	loading_swapped = true
	world.queue_free()
	var maze := Node3D.new()
	maze.set_script(MazeScript)
	add_child(maze)
	world = maze
	maze.set_abyss_player(player)
	_spawn_centipede(maze)
	player.position = MazeScript.UPPER_ENTRY + Vector3(0, 3.65, 0)
	player.rotation.y = 0.0
	player.pitch = 0.3
	player.camera.rotation.x = player.pitch
	player.velocity = Vector3.ZERO

func _spawn_centipede(maze: Node3D) -> void:
	centipede = Node3D.new()
	centipede.set_script(CentipedeScript)
	add_child(centipede)
	centipede.setup(maze, player, self, maze_deaths > 0)

func restart_maze() -> void:
	if phase != "maze":
		return
	maze_deaths += 1
	maze_dying = false
	maze_death_time = 0.0
	maze_hidden = false
	player.movement_locked = false
	player.control_enabled = true
	player.position = MazeScript.SPAWN
	player.velocity = Vector3.ZERO
	player.flashlight_hidden_when_off = false
	player.hand.show()
	player.set_battery_system_enabled(false)
	player.set_flashlight(true)
	centipede.queue_free()
	world.queue_free()
	var maze := Node3D.new()
	maze.set_script(MazeScript)
	add_child(maze)
	world = maze
	maze.set_abyss_player(player)
	_spawn_centipede(maze)
	hud.lens_material.set_shader_parameter("danger", 0.0)

func begin_maze_jumpscare() -> void:
	if phase != "maze" or maze_dying:
		return
	maze_dying = true
	maze_death_time = 0.0
	player.control_enabled = false
	player.velocity = Vector3.ZERO
	hud.lens_material.set_shader_parameter("danger", 1.0)
	sound("centipede_attack")

func _finish_loading() -> void:
	if not loading_swapped:
		if loading_to == "depth":
			_swap_to_depth()
		else:
			_swap_to_maze()
	transition_fx.end()
	player.collision_mask = 1
	player.velocity = Vector3.ZERO
	if loading_to == "depth":
		player.position.y = -3.4
		player.swimming = true
		player.set_battery_system_enabled(true)
		player.flashlight_hidden_when_off = true
		player.set_flashlight(false)
		phase = "depth"
		objective = "Swim toward the green tube"
		say("Swim with Space and Ctrl. The green light waits below.", 5)
	else:
		player.position = MazeScript.UPPER_ENTRY
		player.camera.position.y = 0.98
		player.camera.rotation = Vector3.ZERO
		player.pitch = 0.0
		player.swimming = false
		player.flashlight_hidden_when_off = false
		player.hand.show()
		player.set_battery_system_enabled(false)
		player.set_flashlight(true)
		player.fall_speed_limit = 100.0
		phase = "maze"
		objective = "Find the keys and activate five circuits"
		say("Find four colored keys. Turn on every light. The black lock is in the circle.", 7)
	player.control_enabled = true
	hud.lens_material.set_shader_parameter("darkness", 0.0)
	hud.queue_redraw()

func restart_depth() -> void:
	if phase != "depth":
		return
	depth_loops = 0
	player.position = Vector3(0, -3.4, -13.2)
	player.velocity = Vector3.ZERO
	player.set_flashlight(false)
	world.reset_threat()
	hud.lens_material.set_shader_parameter("danger", 0.0)

func _find_interaction() -> void:
	current_item = -1
	prompt = ""
	if hiding != null and hiding.timer.spot_id != &"":
		prompt = "E  /  Leave hiding spot"
		return
	var best := 3.5
	for i in items.size():
		var item := items[i]
		if item.taken:
			continue
		var offset: Vector3 = item.node.global_position - player.camera.global_position
		var distance := offset.length()
		if distance > best or -player.camera.global_basis.z.dot(offset.normalized()) < 0.82:
			continue
		var ray := PhysicsRayQueryParameters3D.create(player.camera.global_position, item.node.global_position, 1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		best = distance
		current_item = i
		prompt = item.label
	if current_item < 0 and hiding != null and hiding._nearby_spot() != null:
		prompt = "E  /  Hide at " + hiding._nearby_spot().display_name

func interact() -> void:
	_find_interaction()
	if hiding != null and (hiding.timer.spot_id != &"" or (current_item < 0 and hiding._nearby_spot() != null)):
		hiding.interact_requested = true
		return
	if current_item < 0:
		return
	var item := items[current_item]
	match item.kind:
		"fuse":
			item.taken = true
			item.node.hide()
			fuses += 1
			sound("pickup")
			if fuses == 1: # the Ruleset wakes Ronald now
				sound("sting")
				say("Something moved.", 6)
			elif fuses == 3:
				objective = "Restore power in the kitchen"
				say("All three. The breaker is on the far kitchen wall.", 6)
			else:
				say("Two fuses. One more.")
		"cell":
			item.taken = true
			item.node.hide()
			spare_cells += 1
			sound("pickup")
			say("Spare battery collected. Press R to replace the cell.")
		"breaker":
			if fuses < 3:
				say("Three fuses are missing. Check the booths, kitchen and cold storage.", 5)
			elif not power_on:
				power_on = true
				item.taken = true
				breaker_lamp.material_override = Geo.material(Color("72b58d"), 0, 2)
				world.exit_light.light_energy = 2.4
				world.set_powered(true)
				stalker.speed = 2.1
				objective = "Follow the blinking lights to the ball pit"
				sound("power")
				say("The entrance is sealed. Follow the blinking lights back to the ball pit.", 6)
		"exit":
			say("The entrance is sealed. Find the emergency fuses." if not power_on else "Follow the blinking lights to the ball pit.")
				objective = "Reach the west entrance"
				sound("power")
				say("The door has power. Go.", 5)
		"exit":
			if power_on:
				at_exit = true # the Ruleset ends the run next frame
			else:
				say("The magnetic lock has no power. Find the emergency fuses.")
	_find_interaction()

func _find_maze_interaction() -> void:
	maze_kind = ""
	maze_color = ""
	prompt = ""
	var best := 2.8
	if maze_hidden:
		maze_kind = "hide"
		prompt = "E  /  Leave hiding spot"
		return
	var nearby_spot: Node3D = world.closest_hide_spot(player.global_position)
	if nearby_spot:
		best = player.global_position.distance_to(nearby_spot.global_position)
		maze_kind = "hide"
		prompt = "E  /  Hide"
	for color in ["red", "blue", "yellow", "green", "black"]:
		if not world.keys[color]:
			var key_node := world.key_nodes[color] as Node3D
			var distance := player.global_position.distance_to(key_node.global_position)
			if distance < best:
				best = distance
				maze_kind = "key"
				maze_color = color
				prompt = "E  /  Take %s key" % color
		if color != "black":
			var lever_node := world.lever_nodes[color] as Node3D
			var lever_distance := player.global_position.distance_to(lever_node.global_position)
			if lever_distance < best:
				best = lever_distance
				maze_kind = "lever"
				maze_color = color
				prompt = "E  /  Pull %s lever" % color
			var door_node := world.doors[color] as Node3D
			var sockets := world.keyhole_nodes[color] as Node3D
			var door_distance := INF
			for socket in sockets.get_children():
				if str(socket.name).begins_with("WallLock_"):
					door_distance = minf(door_distance, player.global_position.distance_to((socket as Node3D).global_position))
			if door_node.visible and door_distance < best:
				best = door_distance
				maze_kind = "door"
				maze_color = color
				prompt = "E  /  Use %s key in wall lock" % color if world.keys[color] else "E  /  Inspect %s wall lock" % color
	var black_lever := world.lever_nodes.black as Node3D
	var black_lever_distance := player.global_position.distance_to(black_lever.global_position)
	if black_lever_distance < best:
		best = black_lever_distance
		maze_kind = "lever"
		maze_color = "black"
		prompt = "E  /  Pull black lever" if world.cabinet_unlocked else "E  /  Inspect sealed black lever"
	var cabinet := world.find_child("Cabinet_Black_Lock", true, false) as Node3D
	if cabinet and player.global_position.distance_to(cabinet.global_position) < best:
		best = player.global_position.distance_to(cabinet.global_position)
		maze_kind = "cabinet"
		prompt = "E  /  Unlock circle lock"
	var exit_node := world.find_child("Final_Exit_Door", true, false) as Node3D
	if exit_node and player.global_position.distance_to(exit_node.global_position) < best:
		maze_kind = "final"
		prompt = "E  /  Open final door"

func _interact_maze() -> void:
	_find_maze_interaction()
	if maze_kind.is_empty():
		return
	if maze_kind == "hide":
		maze_hidden = not maze_hidden
		player.movement_locked = maze_hidden
		if maze_hidden:
			var spot: Node3D = world.closest_hide_spot(player.global_position)
			if spot:
				player.position = spot.global_position + Vector3.UP * 0.19
		_find_maze_interaction()
		return
	if maze_kind == "final" and world.final_open:
		finish(true)
	else:
		var result: String = world.interact(maze_kind, maze_color)
		if not result.is_empty():
			say(result, 3.5)
			sound("pickup" if maze_kind == "key" else "power")
	_find_maze_interaction()

func replace_cell() -> void:
	if phase != "play":
		return
	if spare_cells <= 0:
		say("No spare cells. Check the booth tables.")
	elif player.battery >= 95:
		say("This cell still has plenty of charge.", 2)
	else:
		spare_cells -= 1
		player.battery = 100
		player.update_battery_indicator()
		player.set_flashlight(true)
		player.animation.play("switch")
		sound("pickup")
		say("Fresh battery.", 2)

func finish(escaped: bool) -> void:
	if phase not in ["play", "maze"]:
		return
	timeout_scene.cancel()
	phase = "won" if escaped else "caught"
	player.control_enabled = false
	stalker.active = false
	stalker.chasing = false
	stalker.update_locomotion(0.0, 0.0)
	horror_feedback.stop()
	message_time = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if escaped and world.has_method("set_powered"):
	if escaped:
		horror_events.clear()
		var tween := create_tween()
		tween.tween_property(world.exit_door, "rotation:y", -1.2, 1.5)
		sound("power")
	elif escaped:
		sound("power")
	else:
		hud.lens_material.set_shader_parameter("danger", 0.0)
		hud.lens_material.set_shader_parameter("darkness", 0.0)
		horror_events.start_catch()
		catch_scene.start(player.camera, stalker, _finish_caught)
	hud.queue_redraw()

func _finish_caught() -> void:
	if phase != "caught":
		return
	phase = "dead"
	horror_events.clear()
	hud.queue_redraw()

func _begin_grapple() -> void:
	if phase != "play" or timeout_scene.camera_locked or player.hiding_locked:
		return
	phase = "grapple"
	player.control_enabled = false
	player.velocity = Vector3.ZERO
	stalker.active = false
	stalker.chasing = false
	stalker.update_locomotion(0.0, 0.0)
	horror_feedback.stop()
	horror_events.play_attack_scream()
	hud.lens_material.set_shader_parameter("danger", 0.0)
	grapple_scene.start(player.camera, stalker, _grapple_won, _grapple_lost)
	hud.queue_redraw()

func _grapple_won() -> void:
	if phase != "grapple":
		return
	phase = "play"
	player.control_enabled = true
	player.toggle_cooldown = 0.0
	player.set_flashlight(true)
	stalker.active = true
	stalker.show()
	stalker.grace = 3.0
	stalker.path.clear()
	stalker.path_timer = 0.0
	stalker.patrol_target_valid = false
	stalker.reset_light_attack()
	horror_events.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	say("He's off you. Run!", 2.5)
	hud.queue_redraw()

func _grapple_lost() -> void:
	if phase != "grapple":
		return
	phase = "dead"
	player.control_enabled = false
	stalker.active = false
	stalker.reset_light_attack()
	horror_events.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.queue_redraw()

func pause_game(paused: bool) -> void:
	if phase in ["home", "loading"]:
		return
	get_tree().paused = paused
	grapple_scene.set_paused(paused)
	if paused:
		timeout_scene.cancel()
		horror_events.clear()
	hud.show_menu("pause" if paused else "")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func set_quality(low: bool) -> void:
	low_quality = low
	player.lamp.shadow_enabled = not low
	get_viewport().scaling_3d_scale = 0.75 if low else 1.0
	if is_instance_valid(hud):
		hud.quality_button.set_pressed_no_signal(low)

func _unhandled_input(event: InputEvent) -> void:
	if phase == "grapple" and not get_tree().paused and grapple_scene.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F11:
				var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
			KEY_F1:
				show_performance = not show_performance
			KEY_F3:
				set_quality(not low_quality)
			KEY_ESCAPE:
				if phase in ["won", "dead"]:
					get_tree().quit()
				elif phase == "home":
					if hud.menu_mode == "options_home":
						hud.show_menu("home")
				elif hud.menu_mode == "options_pause":
					hud.show_menu("pause")
				else:
					pause_game(not get_tree().paused)
			KEY_ENTER:
				if phase in ["won", "dead"]:
					restart()
				elif phase == "intro" and not get_tree().paused:
					finish_intro()
			KEY_SPACE:
				if phase == "intro" and not get_tree().paused:
					finish_intro()
	if phase in ["play", "maze"] and not get_tree().paused:
	if phase == "play" and not get_tree().paused:
		if timeout_scene.camera_locked:
			return
		if event.is_action_pressed("interact"):
			if phase == "maze":
				_interact_maze()
			else:
				interact()
		if phase == "play" and event.is_action_pressed("reload_cell"):
			replace_cell()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud) and phase in ["intro", "play", "depth", "maze"]:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud) and phase in ["intro", "play", "grapple", "caught"]:
		pause_game(true)

func _exit_tree() -> void:
	# Release PCM playback before the audio server shuts down or restarts.
	if is_instance_valid(ambient):
		ambient.stop()
	if is_instance_valid(nightmare_ambient):
		nightmare_ambient.stop()
	for audio in sounds.values():
		if is_instance_valid(audio):
			audio.stop()
