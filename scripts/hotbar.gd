extends Control

var max_slots := 5
var items := []
var selected_slot := 0

@onready var slots := $HBoxContainer.get_children()

func _ready():
	items.resize(max_slots)
	update_slot_appearance()
	
	# Set up anchors for bottom center positioning
	anchors_preset = Control.PRESET_BOTTOM_WIDE
	anchor_bottom = 1.0
	offset_bottom = -400
	
	# Ensure we're on top of everything
	z_index = 100
	show()

func add_item(item_texture, index):
	print("Adding item to hotbar at index: ", index)  # Debug print
	if index < max_slots:
		items[index] = item_texture
		slots[index].texture = item_texture
		update_slot_appearance()
		
func remove_item(index):
	print("Removing item from hotbar at index: ", index)  # Debug print
	if index < max_slots:
		items[index] = null
		slots[index].texture = null
		
		# Shift remaining items to fill the gap
		for i in range(index, items.size() - 1):
			items[i] = items[i + 1]
			slots[i].texture = slots[i + 1].texture
		
		# Clear the last slot
		items[items.size() - 1] = null
		slots[items.size() - 1].texture = null
		
		update_slot_appearance()

func set_selected(index: int):
	if index >= 0 and index < max_slots:
		selected_slot = index
		update_slot_appearance()

func update_slot_appearance():
	for i in range(slots.size()):
		var slot = slots[i]
		if i == selected_slot:
			slot.modulate = Color(1, 1, 1, 1)  # Full brightness for selected
		else:
			slot.modulate = Color(0.5, 0.5, 0.5, 1)  # Dimmed for unselected
