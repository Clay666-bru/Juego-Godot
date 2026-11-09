extends Area2D

enum PickupType { WEAPON, HEALTH }

@export var pickup_type: PickupType = PickupType.WEAPON
@export var weapon_type: int = 1
@export var heal_amount: int = 1
@export var despawn_time: float = 8.0

@onready var weapon_sprite := $WeaponSprite as Sprite2D
@onready var despawn_timer := $DespawnTimer as Timer

var _blinking := false
var _elapsed := 0.0
var _base_y: float
var _cross_vertical: ColorRect
var _cross_horizontal: ColorRect
var _cross_visible := false


func _ready() -> void:
	_base_y = position.y
	_build_cross()
	_update_visual()
	despawn_timer.wait_time = despawn_time
	despawn_timer.one_shot = true
	despawn_timer.timeout.connect(queue_free)
	despawn_timer.start()
	body_entered.connect(_on_body_entered)


func _build_cross() -> void:
	var v := ColorRect.new()
	v.position = Vector2(-4, -16)
	v.size = Vector2(8, 32)
	v.color = Color(0.2, 1, 0.2)
	v.visible = false
	add_child(v)
	_cross_vertical = v

	var h := ColorRect.new()
	h.position = Vector2(-16, -4)
	h.size = Vector2(32, 8)
	h.color = Color(0.2, 1, 0.2)
	h.visible = false
	add_child(h)
	_cross_horizontal = h


func _update_visual() -> void:
	var is_health := pickup_type == PickupType.HEALTH
	weapon_sprite.visible = not is_health
	_cross_vertical.visible = is_health
	_cross_horizontal.visible = is_health
	_cross_visible = is_health


func _process(delta: float) -> void:
	_elapsed += delta

	position.y = _base_y + sin(_elapsed * 3.0) * 4.0

	var remaining := despawn_timer.time_left
	if remaining < 3.0 and not _blinking:
		_blinking = true

	if _blinking:
		var vis := int(_elapsed * 10) % 2 == 0
		if _cross_visible:
			_cross_vertical.visible = vis
			_cross_horizontal.visible = vis
		else:
			weapon_sprite.visible = vis


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	match pickup_type:
		PickupType.WEAPON:
			WeaponManager.switch_to(weapon_type)
		PickupType.HEALTH:
			body.heal(heal_amount)
	Sounds.play_at(Sounds.pickup, global_position)
	queue_free()
