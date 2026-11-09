extends Area2D

var direction := Vector2.RIGHT
var speed := 600.0
var damage := 1
var weapon_type := WeaponManager.WeaponType.PISTOL

@export var bullet_texture: Texture2D = preload("res://assets/sprites/weapons/bullet.png")

@onready var sprite := $Sprite2D as Sprite2D
@onready var visible_notifier := $VisibleOnScreenNotifier2D as VisibleOnScreenNotifier2D


func _ready() -> void:
	var data = WeaponManager.weapon_data[weapon_type]
	speed = data.speed
	damage = data.damage

	rotation = direction.angle()
	sprite.texture = bullet_texture
	body_entered.connect(_on_body_entered)
	visible_notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		Effects.spark(global_position, Color(1, 0.8, 0.2, 1), 4, 40.0)
		Sounds.play_at(Sounds.bullet_hit, global_position, randf_range(0.9, 1.1))
		body.take_damage(damage)
	queue_free()
