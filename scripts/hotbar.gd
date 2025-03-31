extends Control

var max_slots := 5

var items := []

@onready var camera = get_viewport().get_camera_2d()

func _process(delta):
	if camera:
		var screen_size = get_viewport_rect().size
		var bottom_center = camera.get_screen_center_position() + Vector2(0, (screen_size.y / 2) * camera.zoom.y)
		position = Vector2(bottom_center.x - size.x / 2, bottom_center.y - size.y - 80)
		
@onready var slots := $HBoxContainer.get_children()

func _ready():
	items.resize(max_slots)

func add_item(item_texture, index):
	if index < max_slots:
		items[index] = item_texture
		slots[index].texture = item_texture
		
func remove_item(item):
	for i in range(max_slots):
		if items[i] == item:
			items[i] = null
			slots[i].texture = null
			break
