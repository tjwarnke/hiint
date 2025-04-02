extends Control

var max_slots := 5
var items := []
var selected_slot := 0

@onready var slots := $HBoxContainer.get_children()

func _ready():
	items.resize(max_slots)
	update_slot_appearance()
	
	# Set up anchors for bottom center positioning
	anchors_preset = PRESET_BOTTOM_WIDE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_bottom = 1.0
	offset_left = -200.0  # Half of the hotbar width
	offset_right = 200.0  # Half of the hotbar width
	offset_bottom = -20.0  # Distance from bottom of screen
	
	# Ensure we're on top of everything
	z_index = 100
	show()

func add_item(item_texture, index):
	if index < max_slots:
		items[index] = item_texture
		slots[index].texture = item_texture
		update_slot_appearance()
		
func remove_item(index):
	if index < max_slots:
		items[index] = null
		slots[index].texture = null
		update_slot_appearance()

func set_selected(index: int):
	selected_slot = index
	update_slot_appearance()

func update_slot_appearance():
	for i in range(slots.size()):
		var slot = slots[i]
		if i == selected_slot:
			slot.modulate = Color(1, 1, 1, 1)  # Full brightness for selected
		else:
			slot.modulate = Color(0.5, 0.5, 0.5, 1)  # Dimmed for unselected
