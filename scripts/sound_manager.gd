extends Node

# 音效管理器 - 管理游戏音效和音乐

var sound_enabled: bool = true
var music_enabled: bool = true
var sound_volume: float = 1.0
var music_volume: float = 0.8

# 音效字典
var sounds: Dictionary = {}

# 音频播放器池
var audio_pool: Array = []
var bgm_player: AudioStreamPlayer = null
const MAX_AUDIO_PLAYERS = 16

func _ready():
	# 初始化 BGM 播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = linear_to_db(music_volume)
	add_child(bgm_player)
	
	# 初始化音频播放器池
	for i in range(MAX_AUDIO_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.volume_db = linear_to_db(sound_volume)
		audio_pool.append(player)
		add_child(player)
	
	print("音效管理器初始化完成")

func play_bgm(bgm_name: String):
	if not music_enabled:
		return
	
	print("播放背景音乐: ", bgm_name)
	
	# 使用程序化生成的 BGM
	var stream = _create_bgm_stream(bgm_name)
	if stream:
		bgm_player.stream = stream
		bgm_player.play()

func stop_bgm():
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

func _create_bgm_stream(bgm_name: String) -> AudioStream:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 0.5
	return stream

func play_sound(sound_name: String, volume_scale: float = 1.0):
	if not sound_enabled:
		return
	
	var player = _get_available_audio_player()
	if player == null:
		return
	
	var stream = _create_sound_stream(sound_name)
	if stream:
		player.stream = stream
		player.volume_db = linear_to_db(sound_volume * volume_scale)
		player.play()

func _get_available_audio_player() -> AudioStreamPlayer:
	for player in audio_pool:
		if not player.playing:
			return player
	return null

func _create_sound_stream(sound_name: String) -> AudioStream:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 0.1
	
	match sound_name:
		"hit", "attack", "death", "pickup", "level_up":
			return stream
		_:
			return stream

func set_sound_enabled(enabled: bool):
	sound_enabled = enabled

func set_music_enabled(enabled: bool):
	music_enabled = enabled
	if not enabled:
		stop_bgm()

func set_sound_volume(volume: float):
	sound_volume = clamp(volume, 0.0, 1.0)
	for player in audio_pool:
		player.volume_db = linear_to_db(sound_volume)

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	if bgm_player:
		bgm_player.volume_db = linear_to_db(music_volume)
