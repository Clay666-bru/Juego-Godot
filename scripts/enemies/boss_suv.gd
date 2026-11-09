extends CharacterBody2D

signal died()
signal health_changed(current_hp: int, max_hp: int)

@export var boss_hp := 30
@export var move_speed := 100.0
@export var shoot_interval := 0.8

var health: int
var direction := -1
var player: Node2D = null
var _jump_cooldown := 0.0

@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var shoot_timer := $ShootTimer as Timer
@onready var hurt_zone := $HurtZone as Area2D
@onready var obstacle_ray := $ObstacleRay as RayCast2D


func _ready() -> void:
	health = boss_hp
	sprite.play("run")
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_shoot)
	shoot_timer.start()
	hurt_zone.body_entered.connect(_on_hurt_zone_entered)
	player = get_tree().get_first_node_in_group("player")
	health_changed.emit(health, boss_hp)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	_jump_cooldown -= delta
	obstacle_ray.target_position = Vector2(direction * 60, 0)

	if not is_on_floor():
		velocity.y += 1200.0 * delta

	if is_on_floor() and obstacle_ray.is_colliding() and _jump_cooldown <= 0:
		velocity.y = -400.0
		_jump_cooldown = 0.5

	velocity.x = direction * move_speed
	move_and_slide()

	if is_on_floor() and is_on_wall():
		direction *= -1
		sprite.flip_h = direction < 0


func _shoot() -> void:
	if not is_instance_valid(player):
		shoot_timer.start()
		return

	var center := global_position + Vector2(0, -12)
	var bullet_count := 20
	var angle_step := TAU / bullet_count

	for i in bullet_count:
		var bullet := preload("res://scenes/enemies/enemy_bullet.tscn").instantiate()
		var angle := angle_step * i
		bullet.direction = Vector2.RIGHT.rotated(angle)
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = center

	Effects.flash(center, Color(1, 0.5, 0, 1), 36.0, 0.06)
	Sounds.play_at(Sounds.boss_shoot, center, randf_range(0.9, 1.1))
	shoot_timer.start()


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	flash_hit()
	health_changed.emit(health, boss_hp)
	if health <= 0:
		die()


func flash_hit() -> void:
	sprite.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.06).timeout
	if is_queued_for_deletion():
		return
	sprite.modulate = Color.WHITE


func die() -> void:
	Effects.gore(global_position, Color(0.8, 0, 0, 1), 20, 150.0)
	Effects.flash(global_position, Color(1, 1, 1, 1), 40.0, 0.15)
	Sounds.play_at(Sounds.boss_death, global_position)
	for i in 4:
		var pickup := preload("res://scenes/weapons/pickup.tscn").instantiate()
		pickup.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-20, 0))
		pickup.pickup_type = randi() % 2
		if pickup.pickup_type == 0:
			pickup.weapon_type = randi() % 3 + 1
		else:
			pickup.heal_amount = 3
		get_tree().current_scene.add_child(pickup)

	died.emit()
	queue_free()


func _on_hurt_zone_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1)
