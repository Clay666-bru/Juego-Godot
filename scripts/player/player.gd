extends CharacterBody2D

enum State { IDLE, RUN, JUMP, FALL, CROUCH, ROLL, DEAD }

const MAX_SPEED := 350.0
const JUMP_VELOCITY := -550.0
const GRAVITY := 1200.0
const ROLL_SPEED := 500.0
const ROLL_DURATION := 0.25

@export var max_health := 3
@export var invincibility_duration := 1.5

@export var body_texture: Texture2D = preload("res://assets/sprites/player/player_idle.png")
@export var cursor_texture: Texture2D = preload("res://assets/sprites/ui/aim_cursor.png")

var state: State = State.IDLE
var health: int
var facing_direction := 1
var aim_angle := Vector2.RIGHT
var can_shoot := true
var is_invincible := false
var roll_timer := 0.0

@onready var sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var collision_shape := $CollisionShape2D as CollisionShape2D
@onready var aim_helper := $AimHelper as Marker2D
@onready var muzzle := $AimHelper/Muzzle as Marker2D
@onready var floor_detector := $FloorDetector as RayCast2D
@onready var invincibility_timer := $InvincibilityTimer as Timer
@onready var aim_cursor := $AimCursor as Sprite2D
@onready var default_collision_size = collision_shape.shape.size

var hit_color_tween: Tween

signal health_changed(new_health)
signal died()


func _ready() -> void:
	health = max_health
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	aim_cursor.texture = cursor_texture
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	update_health_display()
	_update_animation()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	handle_gravity(delta)
	handle_state(delta)
	handle_aim()
	move_and_slide()
	update_facing()
	_update_animation()


func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta


func handle_state(delta: float) -> void:
	match state:
		State.IDLE, State.RUN, State.CROUCH:
			handle_ground_state(delta)
		State.JUMP, State.FALL:
			handle_air_state()
		State.ROLL:
			handle_roll_state(delta)


func handle_ground_state(_delta: float) -> void:
	if Input.is_action_just_pressed("roll"):
		start_roll()
		return

	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		set_state(State.JUMP)
		return

	var input_dir := Input.get_axis("move_left", "move_right")
	velocity.x = input_dir * MAX_SPEED

	if Input.is_action_pressed("crouch") and is_on_floor():
		set_state(State.CROUCH)
		collision_shape.shape.size = Vector2(default_collision_size.x, default_collision_size.y * 0.5)
		velocity.x = 0
	elif velocity.x != 0:
		set_state(State.RUN)
		collision_shape.shape.size = default_collision_size
	else:
		set_state(State.IDLE)
		collision_shape.shape.size = default_collision_size

	handle_shooting()


func handle_air_state() -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	velocity.x = input_dir * MAX_SPEED

	if velocity.y < 0:
		set_state(State.JUMP)
	else:
		set_state(State.FALL)

	if is_on_floor():
		set_state(State.IDLE)
		return

	handle_shooting()


func handle_roll_state(delta: float) -> void:
	roll_timer -= delta
	if roll_timer <= 0:
		set_state(State.IDLE)
		velocity.x = 0
		is_invincible = false


func start_roll() -> void:
	set_state(State.ROLL)
	roll_timer = ROLL_DURATION
	velocity.x = facing_direction * ROLL_SPEED
	velocity.y = 0
	is_invincible = true


func handle_aim() -> void:
	var mouse_pos := get_global_mouse_position()
	var dir := (mouse_pos - global_position).normalized()
	aim_angle = dir
	aim_helper.rotation = aim_angle.angle()
	aim_cursor.global_position = mouse_pos


func handle_shooting() -> void:
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()


func shoot() -> void:
	can_shoot = false
	var data = WeaponManager.get_current_data()
	var spread = data.spread_degrees

	for i in data.bullet_count:
		var bullet = data.bullet_scene.instantiate()
		bullet.direction = aim_angle.rotated(deg_to_rad(randf_range(-spread, spread)))
		bullet.weapon_type = WeaponManager.current_weapon
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = muzzle.global_position

	Effects.flash(muzzle.global_position, Color(1, 1, 0.4, 1), 48.0, 0.06)
	Sounds.play_at(Sounds.player_shoot, muzzle.global_position, randf_range(0.9, 1.1))

	var fire_rate = data.fire_rate
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true


func update_facing() -> void:
	var mouse_pos := get_global_mouse_position()
	var diff := mouse_pos.x - global_position.x
	if abs(diff) > 4.0:
		facing_direction = 1 if diff > 0 else -1
		sprite.flip_h = facing_direction < 0


func _update_animation() -> void:
	if state == State.DEAD:
		return
	var shooting := Input.is_action_pressed("shoot")
	match state:
		State.IDLE:
			sprite.play("shoot_idle" if shooting else "idle")
		State.RUN:
			sprite.play("run_and_gun" if shooting else "run")
		_:
			sprite.play("idle")


func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	_update_animation()


func take_damage(amount: int = 1) -> void:
	if is_invincible or state == State.DEAD:
		return

	health -= amount
	update_health_display()
	Sounds.play_at(Sounds.player_hit, global_position, randf_range(0.9, 1.1))

	if health <= 0:
		die()
		return

	is_invincible = true
	invincibility_timer.start(invincibility_duration)
	flash_hit()


func die() -> void:
	set_state(State.DEAD)
	velocity = Vector2.ZERO
	modulate = Color(1, 0.3, 0.3)
	Sounds.play_at(Sounds.player_death, global_position)
	died.emit()


func _on_invincibility_timeout() -> void:
	is_invincible = false


func update_health_display() -> void:
	health_changed.emit(health)


func flash_hit() -> void:
	modulate = Color(1, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	tween.tween_interval(0.1)
	tween.tween_property(self, "modulate", Color(1, 0.4, 0.4), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	update_health_display()
