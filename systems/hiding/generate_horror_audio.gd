extends SceneTree
## Original synthesized audio; regenerate with Godot -s this script.
const RATE: int = 22050

func _initialize() -> void:
	var music: PackedByteArray = PackedByteArray()
	music.resize(RATE * 8 * 2)
	for index: int in RATE * 8:
		var t: float = float(index) / RATE
		var beat: float = fmod(t, 0.4)
		var pulse: float = sin(TAU * (56.0 * beat + 20.0 * beat * beat)) * exp(-beat * 20.0)
		var drone: float = sin(TAU * 55.0 * t) + 0.5 * sin(TAU * 58.0 * t) + 0.3 * sin(TAU * 110.0 * t)
		var alarm: float = sin(TAU * 440.0 * t + 5.0 * sin(TAU * 0.5 * t)) * (0.5 + 0.5 * sin(TAU * 0.25 * t))
		var envelope: float = minf(t / 0.03, (8.0 - t) / 0.03)
		music.encode_s16(index * 2, int(clampf((pulse * 0.42 + drone * 0.13 + alarm * 0.08) * envelope, -1.0, 1.0) * 32767))
	write_wave("res://systems/hiding/chase_music.wav", music)
	var tap: PackedByteArray = PackedByteArray()
	tap.resize(int(RATE * 0.22) * 2)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 440
	for index: int in tap.size() / 2:
		var t: float = float(index) / RATE
		var noise: float = rng.randf_range(-1.0, 1.0)
		var sample: float = noise * exp(-t * 160.0) * 0.55 + sin(TAU * 145.0 * t) * exp(-t * 35.0) * 0.42
		if t > 0.04:
			sample += sin(TAU * 270.0 * (t - 0.04)) * exp(-(t - 0.04) * 70.0) * 0.12
		tap.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767))
	write_wave("res://systems/hiding/floor_tap.wav", tap)
	var scream: PackedByteArray = PackedByteArray()
	scream.resize(int(RATE * 1.15) * 2)
	var phase: float = 0.0
	for index: int in scream.size() / 2:
		var t: float = float(index) / RATE
		var frequency: float = 420.0 + 150.0 * sin(t * 2.5) + 35.0 * sin(t * 43.0)
		phase += TAU * frequency / RATE
		var vocal: float = 0.0
		for harmonic: int in range(1, 9):
			var hz: float = frequency * harmonic
			var formant: float = exp(-pow((hz - 850.0) / 430.0, 2.0)) + 0.65 * exp(-pow((hz - 2300.0) / 650.0, 2.0))
			vocal += sin(phase * harmonic) * formant / sqrt(float(harmonic))
		var air: float = rng.randf_range(-1.0, 1.0) * 0.22
		var envelope: float = minf(1.0, t / 0.008) * pow(maxf(0.0, 1.0 - t / 1.15), 0.45)
		var sample: float = clampf((vocal * 0.65 + air) * 1.6, -0.85, 0.85) * envelope
		scream.encode_s16(index * 2, int(sample * 32767))
	write_wave("res://systems/hiding/catch_scream.wav", scream)
	var noise: PackedByteArray = PackedByteArray()
	noise.resize(int(RATE * 0.5) * 2)
	var previous: float = 0.0
	for index: int in noise.size() / 2:
		var sample: float = rng.randf_range(-0.65, 0.65)
		var filtered: float = sample - previous * 0.5
		previous = sample
		noise.encode_s16(index * 2, int(clampf(filtered, -0.85, 0.85) * 32767))
	write_wave("res://systems/hiding/screen_static.wav", noise)
	var crunch: PackedByteArray = PackedByteArray()
	crunch.resize(int(RATE * 0.55) * 2)
	for index: int in crunch.size() / 2:
		var t: float = float(index) / RATE
		var burst: float = fmod(t, 0.11)
		var envelope: float = exp(-burst * 45.0) * maxf(0.0, 1.0 - t / 0.55)
		var sample: float = (rng.randf_range(-0.7, 0.7) + sin(TAU * 83.0 * t) * 0.22) * envelope
		crunch.encode_s16(index * 2, int(clampf(sample, -0.9, 0.9) * 32767))
	write_wave("res://systems/hiding/bite_crunch.wav", crunch)
	quit()

func write_wave(path: String, pcm: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + pcm.size())
	file.store_buffer("WAVEfmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(RATE)
	file.store_32(RATE * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(pcm.size())
	file.store_buffer(pcm)
