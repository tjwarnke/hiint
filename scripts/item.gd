extends Area2D

signal item_picked

var can_be_picked_up = true
var player = null
var player_in_area = false  # Track when player is in the item's area

# Store original properties for debugging
var original_scale = Vector2.ZERO
var original_rotation = 0.0
var original_position = Vector2.ZERO
var original_parent = null

# Default book content in case it's a book without specified content
var default_book_content = "You give it a quick skim, but it's not all that interesting."

@onready var text_box = get_node("/root/World/UI/TextBoxMiddleTop")
@onready var sprite = $Sprite2D

func _ready():
	add_to_group("item")
	print_debug("Initializing item: ", name)
	# Store original properties
	original_scale = scale
	original_rotation = rotation
	original_position = position
	original_parent = get_parent()
	
	# Store original scale in meta data
	set_meta("original_scale_stored", original_scale)
	
	# If this is a book and doesn't have content yet, add default content
	if name.contains("Book") or name.contains("Autobiography"):
		print_debug("Setting up book content for: ", name)
		if not has_meta("book_content"):
			# Set different content based on the book name
			var book_content = default_book_content
			if name.contains("Anna_Autobiography"):
				book_content = "\"Dear Diary, I suspected something was off about Vlad from the beginning.\n\nThe way he would disappear at night, the strange noises from the basement.\n\nI fear what I might discover if I investigate further...\""
			elif name.contains("Vlad_Autobiography"):
				book_content = "\"Upon Alena's death, Anna and I fought over who would inherit the mansion.\n\nAs the first twin to see the light, I claimed birthright.\n\nThe family secrets must remain hidden in these walls.\""
			elif name.contains("Nana_Autobiography"):
				book_content = "\"The Kusnetzov family rose to power in the early 1700s.\n\nIn 1845, I became the first to move to America, with my younger siblings following soon after.\n\nOur family's gifts must be protected at all costs.\""
			set_meta("book_content", book_content)
			print_debug("Book content set for: ", name)
		
		# Ensure the book can be picked up
		can_be_picked_up = true
		monitoring = true
		monitorable = true
		print_debug("Book pickup enabled for: ", name)
	
	# Wait for the Player node to be available
	await get_tree().process_frame
	await get_tree().process_frame  # Wait two frames to ensure World is ready
	
	# Try to find the player node
	var world = get_node_or_null("/root/World")
	if world:
		player = world.get_node_or_null("Player")

func _process(_delta):
	# Skip processing if the player is null
	if player == null:
		return
		
	# Prioritize pickup if player is in range of an item
	if Input.is_action_just_pressed("pick_up") and can_be_picked_up and player_in_area:
		print_debug("Attempting to pick up item: ", name)
		can_be_picked_up = false  # Prevent multiple pickups
		
		# Add a small delay before pickup to prevent conflicts with other items
		await get_tree().create_timer(0.05).timeout
		
		# Make sure player is still valid and we're still in pickup range
		if player and player_in_area:
			emit_signal("item_picked")
			player.pick_up_item(self)
			text_box.visible = false  # Hide tooltip after pickup
			print_debug("Item picked up: ", name)
		else:
			# Reset if pickup failed
			can_be_picked_up = true
			print_debug("Pickup canceled - player moved away: ", name)
		return  # Exit early to prevent dialog from showing
	
	# Show tooltip for selected book
	if player and player.has_method("get_selected_item"):
		var selected_item = player.get_selected_item()
		if selected_item == self and (name.contains("Book") or name.contains("Autobiography")):
			text_box.visible = true
			var key = InputMap.action_get_events("pick_up")[0].as_text()
			text_box.text = "Press '%s' to read book" % key
			print_debug("Showing read prompt for book: ", name)
		elif selected_item != self:
			text_box.visible = false

func _on_player_powerup_ready(powerup_name, value):
	if powerup_name == "Jump":
		# Handle jump powerup
		pass
	elif powerup_name == "Dash":
		# Handle dash powerup
		pass

func _on_player_powerup_used(powerup_name):
	if powerup_name == "Jump":
		# Handle jump powerup used
		pass
	elif powerup_name == "Dash":
		# Handle dash powerup used
		pass

func _on_body_entered(body):
	if body.is_in_group("player"):
		print_debug("Player entered area for item: ", name)
		player = body
		player_in_area = true  # Set player_in_area to true when player enters
		# Only show pickup text if this isn't the currently selected item
		if can_be_picked_up and not (player.has_method("get_selected_item") and player.get_selected_item() == self):
			text_box.visible = true
			# Get the current key binding for pick_up action
			var key = InputMap.action_get_events("pick_up")[0].as_text()
			if name.contains("Book") or name.contains("Autobiography"):
				text_box.text = "Press '%s' to pick up book" % key
			else:
				text_box.text = "Press '%s' to pick up" % key
			print_debug("Showing pickup prompt for item: ", name)

func _on_body_exited(body):
	if body.is_in_group("player"):
		print_debug("Player exited area for item: ", name)
		player = null
		player_in_area = false  # Set player_in_area to false when player exits
		text_box.visible = false

func _on_dropped():
	# This function is called when the item is dropped
	# Reset to original scale
	scale = original_scale
	rotation = original_rotation
	
	# Make sure the item is visible and can be picked up again
	visible = true
	can_be_picked_up = true
	
	# Reset the player reference and area state
	player = null
	player_in_area = false

# Add a method to get the original scale
func get_original_scale() -> Vector2:
	return original_scale
