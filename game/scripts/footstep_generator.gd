extends Node

var _audio_player: AudioStreamPlayer = null
var _audio_generator: AudioStreamGenerator = null
var _is_initialized: bool = false

const FOOTSTEP_VOLUME: float = 0.15

func _ready():
	_initialize_audio()

func _initialize_audio():
	if _is_initialized:
		return
	
	_audio_generator = AudioStreamGenerator.new()
	_audio_generator.mix_rate = 44100
	_audio_generator.buffer_length = 0.1
	
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = _audio_generator
	_audio_player.volume_db = linear_to_db(FOOTSTEP_VOLUME)
	add_child(_audio_player)
	
	_is_initialized = true

func play_footstep(variant: int = 0):
	if not _is_initialized:
		_initialize_audio()
	
	if _audio_player.playing:
		return
	
	_audio_player.play()
	
	var playback = _audio_player.get_stream_playback()
	if playback == null:
		return
	
	var buffer_size = 4410
	var samples = PackedVector2Array()
	
	for i in range(buffer_size):
		var t = float(i) / 44100.0
		var envelope = exp(-t * 80.0)
		
		var base_freq = 80.0 + float(variant) * 20.0
		var freq_mod = sin(t * 40.0) * 15.0
		var freq = base_freq + freq_mod
		
		var sample = sin(t * freq * TAU)
		sample *= envelope
		sample *= 0.5
		
		var high_freq = sin(t * (freq * 2.5) * TAU)
		high_freq *= envelope * 0.2
		sample += high_freq
		
		samples.append(Vector2(sample, sample))
	
	playback.push_buffer(samples)
