extends SceneTree
## Original shriek plus a breathy spectral treatment of the local spoken line.
const RATE: int = 22050

func _initialize() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1313
	var scream: PackedByteArray = PackedByteArray()
	scream.resize(int(RATE * 1.4) * 2)
	var phase: float = 0.0
	var second_phase: float = 0.0
	for index: int in scream.size() / 2:
		var t: float = float(index) / RATE
		var hz: float = 560.0 + 220.0 * sin(t * 2.2) + 45.0 * sin(t * 65.0)
		phase += TAU * hz / RATE
		second_phase += TAU * hz * 0.743 / RATE
		var voice: float = sin(phase) + sin(phase * 2.0) * 0.48 + sin(phase * 3.0) * 0.32
		voice += sin(second_phase) * 0.6 + sin(second_phase * 4.0) * 0.25
		var breath: float = rng.randf_range(-1.0, 1.0) * 0.32
		var envelope: float = minf(1.0, t / 0.004) * minf(1.0, (1.4 - t) / 0.18)
		var sample: float = tanh((voice + breath) * 1.7) * 0.97 * envelope
		scream.encode_s16(index * 2, int(sample * 32767.0))
	write_wave("res://systems/hiding/terror_scream.wav", scream, RATE)
	make_whisper(rng)
	quit()

func make_whisper(rng: RandomNumberGenerator) -> void:
	var source: FileAccess = FileAccess.open("res://systems/hiding/i_see_you.wav", FileAccess.READ)
	source.seek(12)
	var rate: int = RATE
	var pcm: PackedByteArray = PackedByteArray()
	while source.get_position() + 8 <= source.get_length():
		var chunk: String = source.get_buffer(4).get_string_from_ascii()
		var size: int = source.get_32()
		var next: int = source.get_position() + size + (size % 2)
		if chunk == "fmt ":
			assert(source.get_16() == 1, "Speech source must be PCM")
			assert(source.get_16() == 1, "Speech source must be mono")
			rate = source.get_32()
			source.get_32()
			source.get_16()
			assert(source.get_16() == 16, "Speech source must be 16 bit")
		elif chunk == "data":
			pcm = source.get_buffer(size)
		source.seek(next)
	assert(not pcm.is_empty())
	# Independent bands carry the speech's spectral envelopes onto breath noise.
	var centers: Array[float] = [250.0, 450.0, 750.0, 1100.0, 1700.0, 2500.0, 3500.0, 4800.0]
	var low: PackedFloat64Array = PackedFloat64Array()
	var band: PackedFloat64Array = PackedFloat64Array()
	var envelopes: PackedFloat64Array = PackedFloat64Array()
	var noise_low: PackedFloat64Array = PackedFloat64Array()
	var noise_band: PackedFloat64Array = PackedFloat64Array()
	low.resize(8)
	band.resize(8)
	envelopes.resize(8)
	noise_low.resize(8)
	noise_band.resize(8)
	var result: PackedByteArray = PackedByteArray()
	result.resize(pcm.size())
	for index: int in pcm.size() / 2:
		var input: float = float(pcm.decode_s16(index * 2)) / 32768.0
		var noise: float = rng.randf_range(-1.0, 1.0)
		var output: float = input * 0.09
		for k: int in centers.size():
			var f: float = 2.0 * sin(PI * minf(centers[k], rate * 0.2) / rate)
			low[k] += f * band[k]
			band[k] += f * (input - low[k] - 0.8 * band[k])
			envelopes[k] = maxf(absf(band[k]), envelopes[k] * 0.998)
			noise_low[k] += f * noise_band[k]
			noise_band[k] += f * (noise - noise_low[k] - 0.8 * noise_band[k])
			output += noise_band[k] * envelopes[k] * 1.8
		result.encode_s16(index * 2, int(tanh(output * 2.0) * 0.9 * 32767.0))
	write_wave("res://systems/hiding/whisper_see_you.wav", result, rate)

func write_wave(path: String, pcm: PackedByteArray, rate: int) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + pcm.size())
	file.store_buffer("WAVEfmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(rate)
	file.store_32(rate * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(pcm.size())
	file.store_buffer(pcm)
