extends RigidBody2D

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
var default_book_content = "This appears to be an old book. The pages are faded and difficult to read."

@onready var text_box = get_node("/root/World/UI/TextBoxMiddleTop")
@onready var sprite = $Sprite2D
@onready var area = get_node("Area2D")

func _ready():
	add_to_group("item")
	# Store original properties
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	original_scale = scale
	original_rotation = rotation
	original_position = position
	original_parent = get_parent()
	
	# If this is a book and doesn't have content yet, add default content
	if name.contains("Book") or name.contains("Autobiography"):
		if not has_meta("book_content"):
			set_meta("book_content", default_book_content)
	
	# Wait for the Player node to be available
	await get_tree().process_frame
	await get_tree().process_frame  # Wait two frames to ensure World is ready
	
	# Try to find the player node
	var world = get_node_or_null("/root/World")
	if world:
		player = world.get_node_or_null("Player")

func _process(_delta):
	# Prioritize pickup if player is in range of an item
	if player and Input.is_action_just_pressed("pick_up") and can_be_picked_up and player_in_area:
		can_be_picked_up = false  # Prevent multiple pickups
		emit_signal("item_picked")
		self.gravity_scale=0
		self.collision_layer = 100
		player.pick_up_item(self)
		text_box.visible = false  # Hide tooltip after pickup
		return  # Exit early to prevent dialog from showing
	
	# Show tooltip for selected book
	if player and player.has_method("get_selected_item"):
		var selected_item = player.get_selected_item()
		if selected_item == self and (name.contains("Book") or name.contains("Autobiography")):
			text_box.visible = true
			var key = InputMap.action_get_events("pick_up")[0].as_text()
			text_box.text = "Press '%s' to read book" % key
			
			# If the player presses the key to read the book
			if Input.is_action_just_pressed("pick_up"):
				text_box.text = get_meta("book_content")
				# Create a timer to keep the text visible longer
				var timer = get_tree().create_timer(5.0)  # Show text for 5 seconds
				await timer.timeout
				# Only reset the text if this is still the selected item
				if player and player.has_method("get_selected_item") and player.get_selected_item() == self:
					text_box.text = "Press '%s' to read book" % key
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
		player = body
		player_in_area = true  # Set player_in_area to true when player enters
		# Only show pickup text if this isn't the currently selected item
		if can_be_picked_up and not (player.has_method("get_selected_item") and player.get_selected_item() == self):
			text_box.visible = true
			if name.contains("Book") or name.contains("Autobiography"):
				text_box.text = "Press 'e' to pick up book"
			else:
				text_box.text = "Press 'e' to pick up"

func _on_body_exited(body):
	if body.is_in_group("player"):
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
