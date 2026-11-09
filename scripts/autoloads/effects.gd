extends Node

var _flash_texture: Texture2D = null


func _ready() -> void:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_flash_texture = ImageTexture.create_from_image(image)


func flash(world_pos: Vector2, color: Color = Color(1, 1, 0.6, 1), size: float = 32.0, duration: float = 0.08) -> void:
	var s := size / 8.0
	var sprite := Sprite2D.new()
	sprite.texture = _flash_texture
	sprite.modulate = color
	sprite.global_position = world_pos
	sprite.scale = Vector2(s, s) * 0.5
	sprite.centered = true
	sprite.z_index = 100
	get_tree().current_scene.add_child(sprite)

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(s, s), duration)
	tween.parallel().tween_property(sprite, "modulate", Color(color.r, color.g, color.b, 0), duration)
	tween.tween_callback(sprite.queue_free)


func spark(world_pos: Vector2, color: Color = Color(1, 0.8, 0.2, 1), count: int = 4, spread: float = 50.0) -> void:
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = _flash_texture
		sprite.modulate = color
		sprite.global_position = world_pos
		sprite.scale = Vector2(2, 2)
		sprite.centered = true
		sprite.z_index = 100
		get_tree().current_scene.add_child(sprite)

		var dir := Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(10, spread)
		var tween := create_tween()
		tween.tween_property(sprite, "global_position", world_pos + dir, 0.2)
		tween.parallel().tween_property(sprite, "modulate", Color(color.r, color.g, color.b, 0), 0.2)
		tween.tween_callback(sprite.queue_free)


func explosion(world_pos: Vector2, color: Color = Color(1, 0.4, 0.1, 1), count: int = 6, spread: float = 80.0) -> void:
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = _flash_texture
		sprite.modulate = color if i % 2 == 0 else Color(1, 0.8, 0.2, 1)
		sprite.global_position = world_pos
		sprite.scale = Vector2(2, 2)
		sprite.centered = true
		sprite.z_index = 100
		get_tree().current_scene.add_child(sprite)

		var dir := Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(20, spread)
		var tween := create_tween()
		tween.tween_property(sprite, "global_position", world_pos + dir, 0.3)
		tween.parallel().tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.3)
		tween.parallel().tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.3)
		tween.tween_callback(sprite.queue_free)


func blood_splat(world_pos: Vector2) -> void:
	for i in 3:
		flash(world_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)), Color(0.5, 0, 0, 1), randf_range(16, 32), 0.4)


func gore(world_pos: Vector2, color: Color = Color(0.6, 0, 0, 1), count: int = 10, spread: float = 100.0) -> void:
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = _flash_texture
		sprite.modulate = color if i % 3 != 0 else Color(0.4, 0, 0, 1)
		sprite.global_position = world_pos
		sprite.scale = Vector2(randf_range(1.5, 3.5), randf_range(1.5, 3.5))
		sprite.centered = true
		sprite.z_index = 100
		get_tree().current_scene.add_child(sprite)

		var dir := Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(15, spread)
		var tween := create_tween()
		tween.tween_property(sprite, "global_position", world_pos + dir, randf_range(0.25, 0.45))
		tween.parallel().tween_property(sprite, "scale", Vector2(0.2, 0.2), randf_range(0.25, 0.45))
		tween.parallel().tween_property(sprite, "modulate", Color(1, 1, 1, 0), randf_range(0.25, 0.45))
		tween.tween_callback(sprite.queue_free)

	blood_splat(world_pos)
