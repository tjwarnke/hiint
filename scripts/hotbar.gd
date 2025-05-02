extends Control

var max_slots := 5
var items := []
var selected_slot := 0

@onready var slots := $HBoxContainer.get_children()

func _ready():
	items.resize(max_slots)
	update_slot_appearance()
	
	# Set up anchors for bottom center positioning
	anchors_preset = Control.PRESET_TOP_LEFT
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	
	offset_left = 0  # Adjust as needed
	offset_top = 0   # Adjust as needed
	offset_right = 400  # Width if you want to size it explicitly
	offset_bottom = 100 # Height if needed
	
	# Ensure we're on top of everything
	z_index = 100
	show()

func add_item(item_texture, index):
	if index < max_slots:
		items[index] = item_texture
		if slots[index] and item_texture:
			slots[index].texture = item_texture
		update_slot_appearance()
		
func remove_item(index):
	if index < max_slots:
		items[index] = null
		if slots[index]:
			slots[index].texture = null
		
		# Don't shift items, just clear the slot
		update_slot_appearance()

func set_selected(index: int):
	if index >= 0 and index < max_slots:
		selected_slot = index
		update_slot_appearance()

func update_slot_appearance():
	for i in range(slots.size()):
		if i == selected_slot:
			slots[i].modulate = Color(1, 1, 1, 1)  # Selected slot is fully opaque
		else:
			slots[i].modulate = Color(1, 1, 1, 0.5)  # Unselected slots are semi-transparent
