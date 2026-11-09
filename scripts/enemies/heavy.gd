extends CharacterBody2D

@export var max_health := 4
@export var move_speed := 80.0
@export var shoot_interval := 1.5
@export var enemy_texture: Texture2D = preload("res://assets/sprites/enemies/sicario.png")

var health: int
var player: Node2D = null
var _jump_cooldown := 0.0

@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var shoot_timer := $ShootTimer as Timer
@onready var visibility_notifier := $VisibilityNotifier2D as VisibleOnScreenNotifier2D
@onready var obstacle_ray := $ObstacleRay as RayCast2D

signal died()


func _ready() -> void:
	health = max_health
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()
	visibility_notifier.screen_exited.connect(_on_off_screen)
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	_jump_cooldown -= delta

	var dir := (player.global_position - global_position).normalized()

	if move_speed > 0:
		velocity.x = dir.x * move_speed

	sprite.play("run" if velocity.x != 0 else "shoot")

	if not is_on_floor():
		velocity.y += 1200.0 * delta

	var dir_x := signf((player.global_position - global_position).x)
	if dir_x != 0:
		sprite.flip_h = dir_x < 0
	obstacle_ray.target_position = Vector2(dir_x * 50, 0)

	if is_on_floor() and obstacle_ray.is_colliding() and _jump_cooldown <= 0:
		velocity.y = -400.0
		_jump_cooldown = 0.5

	move_and_slide()


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	flash_hit()
	Sounds.play_at(Sounds.enemy_hit, global_position, randf_range(0.9, 1.1))
	if health <= 0:
		die()


func die() -> void:
	Effects.gore(global_position, Color(0.7, 0, 0, 1), 12, 100.0)
	Sounds.play_at(Sounds.enemy_death, global_position)
	var wp := preload("res://scenes/weapons/pickup.tscn").instantiate()
	wp.global_position = global_position
	wp.pickup_type = 0
	wp.weapon_type = randi() % 3 + 1
	get_tree().current_scene.add_child(wp)

	var hp := preload("res://scenes/weapons/pickup.tscn").instantiate()
	hp.global_position = global_position
	hp.pickup_type = 1
	hp.heal_amount = 3
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
	var spread := 12.0
	var muzzle_pos := global_position + Vector2((1 if not sprite.flip_h else -1) * 20, -8)

	for i in 3:
		var bullet := preload("res://scenes/enemies/enemy_bullet.tscn").instantiate()
		bullet.direction = Vector2(dir.x, 0.0).normalized().rotated(deg_to_rad(randf_range(-spread, spread)))
		bullet.damage = 1
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = muzzle_pos

	Effects.flash(muzzle_pos, Color(1, 0.6, 0.1, 1), 24.0, 0.05)
	Sounds.play_at(Sounds.enemy_shoot, muzzle_pos, randf_range(0.9, 1.1))
	shoot_timer.start()
