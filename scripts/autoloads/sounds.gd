extends Node

@export var player_shoot: AudioStream
@export var player_hit: AudioStream
@export var player_death: AudioStream
@export var enemy_shoot: AudioStream
@export var enemy_hit: AudioStream
@export var enemy_death: AudioStream
@export var boss_shoot: AudioStream
@export var boss_death: AudioStream
@export var pickup: AudioStream
@export var bullet_hit: AudioStream
@export var bgm: AudioStream

@onready var _music_player := AudioStreamPlayer.new()


func _ready() -> void:
	if not player_shoot:
		var s := load("res://assets/audio/sfx/shot.mp3")
		player_shoot = s if s else _beep(880, 0.05)
	if not player_hit:
		var s := load("res://assets/audio/sfx/hit.mp3")
		player_hit = s if s else _beep(220, 0.12)
	if not player_death:
		var s := load("res://assets/audio/sfx/death.mp3")
		player_death = s if s else _beep(140, 0.4)
	if not enemy_shoot:
		var s := load("res://assets/audio/sfx/shot.mp3")
		enemy_shoot = s if s else _beep(660, 0.04)
	if not enemy_hit:
		var s := load("res://assets/audio/sfx/hit.mp3")
		enemy_hit = s if s else _beep(330, 0.06)
	if not enemy_death:
		var s := load("res://assets/audio/sfx/death.mp3")
		enemy_death = s if s else _beep(200, 0.15)
	if not boss_shoot:
		var s := load("res://assets/audio/sfx/shot.mp3")
		boss_shoot = s if s else _beep(440, 0.08)
	if not boss_death:
		var s := load("res://assets/audio/sfx/death.mp3")
		boss_death = s if s else _beep(100, 0.5)
	if not pickup:
		var s := load("res://assets/audio/sfx/pickup.mp3")
		pickup = s if s else _beep(1200, 0.1)
	if not bullet_hit:
		var s := load("res://assets/audio/sfx/hit.mp3")
		bullet_hit = s if s else _beep(550, 0.03)

	if not bgm:
		var s := load("res://assets/audio/sfx/shot.mp3")
		bgm = s if s else _beep(60, 2.0)

	var menu_bgm := load("res://assets/audio/music/menu.mp3")
	_music_player.bus = &"Master"
	_music_player.finished.connect(_loop_bgm)
	add_child(_music_player)
	play_bgm(menu_bgm if menu_bgm else bgm)


func play_bgm(stream: AudioStream) -> void:
	if not stream:
		return
	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()


func _loop_bgm() -> void:
	_music_player.play()


func play_at(stream: AudioStream, world_pos: Vector2, pitch: float = 1.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = world_pos
	player.pitch_scale = pitch
	get_tree().current_scene.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _beep(freq: float, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * dur)
	var data := PackedByteArray()
	data.resize(frames)
	for i in frames:
		var t := float(i) / rate
		var env := 1.0 - t / dur
		var val := sin(2.0 * PI * freq * t) * env * 0.4
		data[i] = int(clamp(val * 0.5 + 0.5, 0.0, 1.0) * 255.0)
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = rate
	return wav
