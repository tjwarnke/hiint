extends Sprite2D

@onready var camera = get_viewport().get_camera_2d()
var PlayerScene = preload("res://scenes/Player.tscn")  
var player

func _process(delta):
	if camera:
		var screen_size = get_viewport_rect().size
		var bottom_center = camera.get_screen_center_position() + Vector2(0, (screen_size.y / 2) * camera.zoom.y)
		position = Vector2(bottom_center.x, bottom_center.y - (texture.get_height() / 2) - 10)
	
	
	
