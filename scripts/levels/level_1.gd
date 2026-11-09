extends Node2D

@export var background_texture: Texture2D
@export var bg_offset_y: float = 0.0

const SICARIO := preload("res://scenes/enemies/sicario.tscn")
const HEAVY := preload("res://scenes/enemies/heavy.tscn")
const SNIPER := preload("res://scenes/enemies/sniper.tscn")
const BOSS := preload("res://scenes/enemies/boss_suv.tscn")

var active_enemies: Array[Node] = []
var current_wave: int = 0
var between_waves: bool = false

var ground_spawns: Array[Marker2D] = []
var high_spawns: Array[Marker2D] = []
var _train_strips: Array[Sprite2D] = []
var _train_speed: float = 1000.0
var _bg_scroll_speed: float = 500.0
var _strip_texture: Texture2D
var _bg_sprites: Array[Sprite2D] = []
var _bg_layer: CanvasLayer

signal wave_started(wave_number: int, is_boss: bool)
signal boss_spawned(boss: Node)


func get_current_wave() -> int:
	return current_wave


func _ready() -> void:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_strip_texture = ImageTexture.create_from_image(img)

	_bg_layer = CanvasLayer.new()
	_bg_layer.layer = -1
	add_child(_bg_layer)

	var tex := background_texture
	if not tex:
		tex = load("res://assets/sprites/tilesets/desert.jpg")

	_bg_sprites.append(Sprite2D.new())
	if tex:
		_bg_sprites[0].texture = tex
	_bg_sprites[0].centered = false
	_bg_sprites[0].position = Vector2(0, bg_offset_y)
	_bg_layer.add_child(_bg_sprites[0])

	var tex_w := tex.get_width() if tex else 1742
	var bg2 := Sprite2D.new()
	bg2.texture = tex
	bg2.centered = false
	bg2.position = Vector2(tex_w, bg_offset_y)
	_bg_layer.add_child(bg2)
	_bg_sprites.append(bg2)

	for i in 6:
		var strip := Sprite2D.new()
		strip.texture = _strip_texture
		strip.scale = Vector2(randf_range(80, 200), randf_range(2, 5))
		strip.modulate = Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 0.8))
		strip.position = Vector2(randf_range(0, 2200), randf_range(350, 570))
		_bg_layer.add_child(strip)
		_train_strips.append(strip)

	for child in $Spawners/Ground.get_children():
		var m := child as Marker2D
		if m:
			ground_spawns.append(m)
	for child in $Spawners/High.get_children():
		var m := child as Marker2D
		if m:
			high_spawns.append(m)

	get_tree().create_timer(1.0).timeout.connect(start_next_wave)


func _process(delta: float) -> void:
	var tex_w := _bg_sprites[0].texture.get_width() if _bg_sprites[0].texture else 1742
	for s in _bg_sprites:
		s.position.x -= _bg_scroll_speed * delta
	if _bg_sprites[0].position.x + tex_w <= 0:
		_bg_sprites[0].position.x = _bg_sprites[1].position.x + tex_w
		_bg_sprites.reverse()

	for strip in _train_strips:
		strip.position = Vector2(strip.position.x - _train_speed * delta, strip.position.y)
		if strip.position.x + strip.scale.x * 2 < -200:
			strip.position = Vector2(2200, strip.position.y)


func start_next_wave() -> void:
	between_waves = false
	var wave := _get_wave(current_wave)
	current_wave += 1
	var is_boss := wave.has("Boss")
	wave_started.emit(current_wave, is_boss)

	if is_boss:
		_spawn_boss()
		return

	for enemy_type in wave.keys():
		var count := wave[enemy_type] as int
		for j in count:
			var spawns: Array[Marker2D] = ground_spawns
			if enemy_type == "Sniper":
				spawns = high_spawns
			var spawn_point = spawns.pick_random()
			var enemy := _create_enemy(enemy_type, spawn_point.global_position)
			if enemy:
				add_child(enemy)
				active_enemies.append(enemy)
				if enemy.has_signal("died"):
					enemy.died.connect(_on_enemy_died.bind(enemy))


func _get_wave(wave_idx: int) -> Dictionary:
	var w := wave_idx + 1
	if w % 5 == 0:
		return { "Boss": 1 }

	var sicarios := mini(2 + wave_idx / 2, 10)
	var heavies := mini(wave_idx / 3, 5)
	var snipers := mini(wave_idx / 4, 4)

	var result: Dictionary = {}
	if sicarios > 0:
		result["Sicario"] = sicarios
	if heavies > 0:
		result["Heavy"] = heavies
	if snipers > 0:
		result["Sniper"] = snipers
	return result


func _spawn_boss() -> void:
	var spawn := $Spawners/BossSpawn as Marker2D
	var boss := BOSS.instantiate()
	boss.global_position = spawn.global_position
	boss.boss_hp = 20 + (current_wave / 5) * 10
	boss.shoot_interval = maxf(0.5, 1.5 - (current_wave / 5) * 0.1)
	add_child(boss)
	boss_spawned.emit(boss)
	active_enemies.append(boss)
	if boss.has_signal("died"):
		boss.died.connect(_on_enemy_died.bind(boss))


func _create_enemy(type: String, pos: Vector2) -> Node:
	var scene: PackedScene
	match type:
		"Sicario": scene = SICARIO
		"Heavy": scene = HEAVY
		"Sniper": scene = SNIPER
		_: return null

	var instance := scene.instantiate() as Node2D
	instance.global_position = pos
	return instance


func _on_enemy_died(_enemy: Node) -> void:
	active_enemies.erase(_enemy)
	if active_enemies.is_empty() and not between_waves:
		between_waves = true
		get_tree().create_timer(2.0).timeout.connect(start_next_wave)
