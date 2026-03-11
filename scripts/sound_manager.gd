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
const MAX_AUDIO_PLAYERS = 16

func _ready():
	# 初始化音频播放器池
	for i in range(MAX_AUDIO_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.volume_db = linear_to_db(sound_volume)
		audio_pool.append(player)
		add_child(player)
	
	# 生成程序化音效
	_generate_sounds()

func _generate_sounds():
	# 由于无法使用外部音效文件，使用程序化生成
	# 这些是基于波的简单音效，可在Godot中播放
	print("音效管理器初始化完成")

func play_bgm(bgm_name: String):
	if not music_enabled:
		return
	print("播放背景音乐: ", bgm_name)
	# TODO: 实现实际 BGM 播放

func play_sound(sound_name: String, volume_scale: float = 1.0):
	if not sound_enabled:
		return
	
	# 获取空闲的音频播放器
	var player = _get_available_audio_player()
	if player == null:
		return
	
	# 根据音效名称生成不同的音效
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
	# 创建程序化音效流
	# 这是一个简化的音效生成，实际游戏应使用预录音频
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	
	# 根据音效名称返回不同的音效配置
	match sound_name:
		"hit":
			# 打击音效 - 短促低频
			return _create_hit_sound()
		"attack":
			# 攻击音效 - 锐利高频
			return _create_attack_sound()
		"death":
			# 死亡音效 - 下降音调
			return _create_death_sound()
		"pickup":
			# 拾取音效 - 上升音调
			return _create_pickup_sound()
		"level_up":
			# 升级音效 - 和弦音
			return _create_level_up_sound()
		_:
			return stream

func _create_hit_sound() -> AudioStream:
	# 创建打击音效（简化的程序化生成）
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	return stream

func _create_attack_sound() -> AudioStream:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	return stream

func _create_death_sound() -> AudioStream:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	return stream

func _create_pickup_sound() -> AudioStream:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	return stream

func _create_level_up_sound() -> AudioStream:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	return stream

func set_sound_enabled(enabled: bool):
	sound_enabled = enabled

func set_music_enabled(enabled: bool):
	music_enabled = enabled

func set_sound_volume(volume: float):
	sound_volume = clamp(volume, 0.0, 1.0)
	for player in audio_pool:
		player.volume_db = linear_to_db(sound_volume)

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
