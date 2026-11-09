extends Area2D

var direction := Vector2.LEFT
var speed := 400.0
var damage := 1

@export var bullet_texture: Texture2D = preload("res://assets/sprites/enemies/enemy_bullet.png")

@onready var sprite := $Sprite2D as Sprite2D
@onready var visible_notifier := $VisibleOnScreenNotifier2D as VisibleOnScreenNotifier2D


func _ready() -> void:
	sprite.texture = bullet_texture
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	visible_notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
