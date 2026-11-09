extends CanvasLayer

@export var bg_texture: Texture2D
@export var train_speed: float = 1000.0
@export var bg_scroll_speed: float = 500.0

var _bg_sprites: Array[Sprite2D] = []
var _train_strips: Array[Sprite2D] = []
var _strip_texture: Texture2D


func _ready() -> void:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_strip_texture = ImageTexture.create_from_image(img)

	var tex := bg_texture
	if not tex:
		tex = load("res://assets/sprites/tilesets/desert.jpg")

	var tex_w := tex.get_width() if tex else 1742
	for i in 2:
		var s := Sprite2D.new()
		if tex:
			s.texture = tex
		s.centered = false
		s.position = Vector2(i * tex_w, -200)
		s.modulate = Color(0.75, 0.75, 0.75)
		s.z_index = -1
		add_child(s)
		_bg_sprites.append(s)

	for i in 6:
		var strip := Sprite2D.new()
		strip.texture = _strip_texture
		strip.scale = Vector2(randf_range(80, 200), randf_range(2, 5))
		strip.modulate = Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 0.8))
		var vp_w := get_viewport().get_visible_rect().size.x
		strip.position = Vector2(randf_range(0, vp_w + 500), randf_range(350, 570))
		strip.z_index = -1
		add_child(strip)
		_train_strips.append(strip)


func _process(delta: float) -> void:
	var tex_w := _bg_sprites[0].texture.get_width() if _bg_sprites[0].texture else 1742
	for s in _bg_sprites:
		s.position.x -= bg_scroll_speed * delta
	if _bg_sprites[0].position.x + tex_w <= 0:
		_bg_sprites[0].position.x = _bg_sprites[1].position.x + tex_w
		_bg_sprites.reverse()

	for strip in _train_strips:
		strip.position.x -= train_speed * delta
		if strip.position.x + strip.scale.x * 2 < -200:
			strip.position.x = get_viewport().get_visible_rect().size.x + 200


func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
