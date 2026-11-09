extends CharacterBody2D

@export var max_health := 1
@export var shoot_interval := 0.8
@export var enemy_texture: Texture2D = preload("res://assets/sprites/enemies/sicario.png")

var health: int
var player: Node2D = null

@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var shoot_timer := $ShootTimer as Timer
@onready var visibility_notifier := $VisibilityNotifier2D as VisibleOnScreenNotifier2D

signal died()


func _ready() -> void:
	health = max_health
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()
	visibility_notifier.screen_exited.connect(_on_off_screen)
	player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var dir := (player.global_position - global_position).normalized()
	if abs(dir.x) > 0.1:
		sprite.flip_h = dir.x < 0
	sprite.play("shoot")


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	flash_hit()
	Sounds.play_at(Sounds.enemy_hit, global_position, randf_range(0.9, 1.1))
	if health <= 0:
		die()


func die() -> void:
	Effects.gore(global_position, Color(0.6, 0, 0.1, 1), 10, 80.0)
	Sounds.play_at(Sounds.enemy_death, global_position)
	if randf() < 0.5:
		var hp := preload("res://scenes/weapons/pickup.tscn").instantiate()
		hp.global_position = global_position
		hp.pickup_type = 1
		hp.heal_amount = 1
		get_tree().current_scene.add_child(hp)
	died.emit()
	queue_free()


func flash_hit() -> void:
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.08).timeout
	modulate = Color.WHITE


func _on_off_screen() -> void:
	died.emit()
	queue_free()


func _on_shoot_timer_timeout() -> void:
	shoot()


func shoot() -> void:
	if not is_instance_valid(player):
		shoot_timer.start()
		return

	var dir := (player.global_position - global_position).normalized()
	var muzzle_pos := global_position + Vector2(0, -8)
	var bullet := preload("res://scenes/enemies/enemy_bullet.tscn").instantiate()
	bullet.direction = dir
	bullet.speed = 900.0
	bullet.damage = 1
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle_pos
	Effects.flash(muzzle_pos, Color(1, 0.4, 0.2, 1), 28.0, 0.04)
	Sounds.play_at(Sounds.enemy_shoot, muzzle_pos, randf_range(0.9, 1.1))
	shoot_timer.start()
