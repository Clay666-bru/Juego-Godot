extends Node

@export var starting_level: PackedScene = preload("res://scenes/levels/level_1.tscn")

var current_level: Node = null
var _weapon_names := ["Pistola", "Ametralladora", "Escopeta", "Láser"]
var _game_over := false
var _last_health := 3

@onready var world := $World as Node2D
@onready var level_container := $World/LevelContainer as Node2D
@onready var player := $World/Player as Node2D
@onready var camera := $World/CameraController as Camera2D
@onready var health_label := $UI/HealthLabel as Label
@onready var weapon_label := $UI/WeaponLabel as Label
@onready var wave_label := $UI/WaveAnnouncement as Label
@onready var boss_health_bar := $UI/BossHealthBar as Control
@onready var boss_health_fill := $UI/BossHealthBar/Fill as ColorRect
@onready var game_over_overlay := $UI/GameOverOverlay as ColorRect
@onready var stats_label := $UI/GameOverOverlay/StatsLabel as Label


func _ready() -> void:
	camera.target = player
	_last_health = player.max_health
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	var level_bgm := load("res://assets/audio/music/level.mp3")
	if level_bgm:
		Sounds.play_bgm(level_bgm)
	load_level(starting_level)


func _process(_delta: float) -> void:
	weapon_label.text = _weapon_names[WeaponManager.current_weapon]
	if _game_over and Input.is_key_pressed(KEY_R):
		restart_game()


func _on_player_health_changed(new_health: int) -> void:
	health_label.text = "Vida: " + str(new_health) + "/" + str(player.max_health)
	if new_health < _last_health:
		camera.shake(10.0, 0.15)
	_last_health = new_health


func _on_player_died() -> void:
	_game_over = true
	var wave := 0
	if current_level and current_level.has_method("get_current_wave"):
		wave = current_level.get_current_wave()
	stats_label.text = "Oleada alcanzada: " + str(wave)
	game_over_overlay.visible = true


func restart_game() -> void:
	_game_over = false
	# Borra balas, pickups, efectos y sonidos sueltos de la partida anterior
	for child in get_children():
		if child != world and child != $UI:
			child.queue_free()
	game_over_overlay.visible = false
	boss_health_bar.visible = false
	player.modulate = Color.WHITE
	player.velocity = Vector2.ZERO
	player.health = player.max_health
	player.state = 0
	player.can_shoot = true
	player.is_invincible = false
	_last_health = player.max_health
	player.health_changed.emit(player.health)
	WeaponManager.switch_to(WeaponManager.WeaponType.PISTOL)
	load_level(starting_level)


func load_level(level_scene: PackedScene) -> void:
	if current_level:
		current_level.queue_free()

	current_level = level_scene.instantiate()
	level_container.add_child(current_level)

	var start_pos := current_level.get_node_or_null("StartPosition") as Marker2D
	if start_pos:
		player.global_position = start_pos.global_position

	if current_level.has_signal("wave_started"):
		current_level.wave_started.connect(_on_wave_started)
	if current_level.has_signal("boss_spawned"):
		current_level.boss_spawned.connect(_on_boss_spawned)


func _on_wave_started(wave_number: int, is_boss: bool) -> void:
	var text := "Oleada " + str(wave_number)
	if is_boss:
		text = "¡JEFE EN CAMINO!"

	wave_label.text = text
	wave_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
	wave_label.visible = true
	wave_label.modulate = Color(1, 1, 1, 1)

	var tween := create_tween()
	tween.tween_property(wave_label, "modulate", Color(1, 1, 1, 0), 0.5).set_delay(2.0)
	tween.tween_callback(func(): wave_label.visible = false)


func _on_boss_spawned(boss: Node) -> void:
	boss_health_bar.visible = true
	var max_hp := boss.get("boss_hp") as int
	var current_hp := boss.get("health") as int
	boss_health_fill.anchor_right = float(current_hp) / float(max_hp)

	if boss.has_signal("health_changed"):
		boss.health_changed.connect(_on_boss_health_changed.bind(boss))
	if boss.has_signal("died"):
		boss.died.connect(_on_boss_died)


func _on_boss_health_changed(current_hp: int, max_hp: int, _boss: Node) -> void:
	boss_health_fill.anchor_right = float(current_hp) / float(max_hp)


func _on_boss_died() -> void:
	boss_health_bar.visible = false
	camera.shake(16.0, 0.4)
