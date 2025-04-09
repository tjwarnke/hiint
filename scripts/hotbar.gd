extends Control

var max_slots := 5
var items := []
var selected_slot := 0

@onready var slots := $HBoxContainer.get_children()

func _ready():
	print("Hotbar: _ready called")
	items.resize(max_slots)
	update_slot_appearance()
	
	# Set up anchors for bottom center positioning
	anchors_preset = Control.PRESET_BOTTOM_WIDE
	anchor_bottom = 1.0
	offset_bottom = -400
	
	# Ensure we're on top of everything
	z_index = 100
	show()
	print("Hotbar: Initialized with ", slots.size(), " slots")

func add_item(item_texture, index):
	print("Hotbar: Adding item at index: ", index)
	print("Hotbar: Item texture: ", item_texture)
	if index < max_slots:
		items[index] = item_texture
		if slots[index] and item_texture:
			slots[index].texture = item_texture
			print("Hotbar: Set texture for slot ", index)
		else:
			print("Hotbar: Failed to set texture - slot or texture is null")
		update_slot_appearance()
	else:
		print("Hotbar: Index out of range: ", index)
		
func remove_item(index):
	print("Hotbar: Removing item at index: ", index)
	if index < max_slots:
		items[index] = null
		if slots[index]:
			slots[index].texture = null
			print("Hotbar: Cleared slot ", index)
		else:
			print("Hotbar: Failed to clear slot - slot is null")
		
		# Don't shift items, just clear the slot
		update_slot_appearance()
	else:
		print("Hotbar: Index out of range: ", index)

func set_selected(index: int):
	print("Hotbar: Setting selected slot to: ", index)
	if index >= 0 and index < max_slots:
		selected_slot = index
		update_slot_appearance()
	else:
		print("Hotbar: Invalid selection index: ", index)

func update_slot_appearance():
	print("Hotbar: Updating slot appearances")
	for i in range(slots.size()):
		if i == selected_slot:
			slots[i].modulate = Color(1, 1, 1, 1)  # Selected slot is fully opaque
			print("Hotbar: Slot ", i, " is selected")
		else:
			slots[i].modulate = Color(1, 1, 1, 0.5)  # Unselected slots are semi-transparent
			print("Hotbar: Slot ", i, " is not selected")
