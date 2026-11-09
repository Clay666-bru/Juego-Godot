extends Camera2D

@export var target: Node2D = null
@export var level_bounds: Rect2 = Rect2(0, 0, 2000, 600)


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	limit_left = int(level_bounds.position.x)
	limit_right = int(level_bounds.position.x + level_bounds.size.x)
	limit_top = int(level_bounds.position.y)
	limit_bottom = int(level_bounds.position.y + level_bounds.size.y)
	if target:
		global_position = target.global_position


func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position


func shake(intensity: float = 8.0, duration: float = 0.2) -> void:
	if not is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_method(_apply_shake, intensity, 0.0, duration)
	tween.tween_callback(func(): offset = Vector2.ZERO)


func _apply_shake(remaining: float) -> void:
	offset = Vector2(randf_range(-remaining, remaining), randf_range(-remaining, remaining))
