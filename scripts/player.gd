extends CharacterBody2D

# Movement variables
var max_speed = 800
var dash_speed = 2000  # Speed for dashing
var acceleration = 2000
var deceleration = 2000
var air_control = 2200  # Less control in the air
var jump_force = -1600  
var gravity = 4000
var fast_fall_gravity = 5000  # Stronger gravity when fast-falling
var jump_release_reduction = 0.5  # Reduces jump height if released early
var inventory = []  
var torch = null
var dash_able = false
var is_dashing = false
var dash_time = 0.15  # Duration of dash
var dash_timer = 0.0
var expected_gravity = gravity #allows for gravity to be temporarily changed
# Velocity tracking
var target_speed = 0  
var is_fast_falling = false  # Track fast-fall state
var max_dash = 0
var num_dash = 0
@onready var dash_sound = $dash_sound


@export var max_jumps: int = 1  
var jumps_left: int
var item_type = ""
var collected_powerups = []  # Track collected powerups

var can_move = true
var is_picking_up = false  # Flag to prevent multiple simultaneous pickups

@onready var hotbar = get_node("/root/World/UI/Hotbar")
var num_items := 0
var selected_item_index := 0
var held_items = []

# Book reading UI elements
var read_dialog = null
var is_reading_book = false
var close_button = null

func _ready():
	jumps_left = max_jumps  # Ensure jumps are initialized correctly
	add_to_group("player")
	
	# Create read dialog for books
	create_read_dialog()
	
	# Create an area detector for item pickups
	create_pickup_detector()
	
	# Connect to powerup signals more robustly
	call_deferred("connect_to_powerups")
	# Also set up a timer to regularly check for new powerups
	var powerup_check_timer = Timer.new()
	powerup_check_timer.wait_time = 1.0  # Check every second
	powerup_check_timer.autostart = true
	powerup_check_timer.timeout.connect(connect_to_powerups)
	add_child(powerup_check_timer)

# Create a read dialog for displaying book content
func create_read_dialog():
	# Create the read dialog if it doesn't exist already
	if read_dialog != null:
		return
	
	# Create a panel for the book content
	read_dialog = RichTextLabel.new()
	read_dialog.name = "ReadDialog"
	read_dialog.size = Vector2(800, 400)
	read_dialog.position = Vector2(get_viewport().size.x / 2 - 400, get_viewport().size.y / 2 - 200)
	read_dialog.visible = false
	read_dialog.bbcode_enabled = true
	read_dialog.scroll_active = true
	get_tree().root.add_child(read_dialog)
	
	# Create a panel background
	var panel = Panel.new()
	panel.name = "Panel"
	panel.size = read_dialog.size
	panel.position = Vector2.ZERO
	read_dialog.add_child(panel)
	
	# Move the RichTextLabel content to be on top of the panel
	read_dialog.position = panel.position
	read_dialog.size = panel.size
	
	# Create a close button
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.size = Vector2(30, 30)
	close_button.position = Vector2(read_dialog.size.x - 40, 10)
	close_button.text = "X"
	close_button.visible = false  # Start hidden
	
	# Connect the close button signal
	close_button.pressed.connect(close_read_dialog)
	
	# Add the close button to the UI
	get_tree().root.add_child(close_button)
	
	# Ensure the read dialog is on top
	read_dialog.z_index = 100

# Close the read dialog and resume gameplay
func close_read_dialog():
	if read_dialog and read_dialog.visible:
		read_dialog.visible = false
		close_button.visible = false  # Ensure close button is hidden
		is_reading_book = false
		# Don't set can_move here, as it might override other movement restrictions
		# Instead check if there are no other restrictions in place
		if not is_picking_up and not is_dashing:
			can_move = true

# Open the read dialog with book content
func open_read_dialog(content):
	if not read_dialog:
		create_read_dialog()
	
	is_reading_book = true
	can_move = false
	
	# Set read dialog content and show it
	read_dialog.text = content
	read_dialog.visible = true
	
	# Position close button
	var dialog_size = read_dialog.size
	close_button.position = Vector2(dialog_size.x - 30, 10)  # Position in top-right corner
	close_button.text = "X"  # Simple X button
	close_button.visible = true

func get_input(delta):
	if not can_move:
		velocity = Vector2.ZERO
		return
	
	var direction = Input.get_axis("left", "right")  
	var is_jumping = Input.is_action_just_pressed("jump")
	var is_releasing_jump = Input.is_action_just_released("jump")
	var is_pressing_fast_fall = Input.is_action_just_pressed("fast_fall")  
	var is_dashing_pressed = Input.is_action_just_pressed("dash")  # Dash key



	if dash_able and is_dashing_pressed and not is_dashing and num_dash > 0 and not is_on_floor():
		is_dashing = true
		dash_sound.play()
		dash_timer = dash_time
		velocity.x = dash_speed * direction  # Dash in facing direction
		gravity = 0
		num_dash -= 1
		

	# If not dashing, apply normal movement
	if not is_dashing:
		target_speed = max_speed * direction
		var accel = acceleration if is_on_floor() else air_control
		var decel = deceleration if is_on_floor() else air_control / 2.0
		gravity = expected_gravity
		if direction != 0:
			velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, decel * delta)

	# Jumping logic
	if is_jumping and jumps_left > 0:
		is_fast_falling = false  
		velocity.y = jump_force  
		jumps_left -= 1  
		

	# Reduce jump height if released early
	if is_releasing_jump and velocity.y < 0:
		velocity.y *= jump_release_reduction
	
	# Fast-falling activation
	if is_pressing_fast_fall and velocity.y > 0 and not is_on_floor():
		is_fast_falling = true  

func _physics_process(delta):
	# Apply gravity unless dashing
	if not is_on_floor():
		if velocity.y < 0:  
			velocity.y += gravity * 0.8 * delta  
		elif is_fast_falling:  
			velocity.y += fast_fall_gravity * delta
		else:  
			velocity.y += gravity * delta
	else:
		jumps_left = max_jumps  
		is_fast_falling = false  
		num_dash = max_dash

	# Handle dash timing
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false  # End dash
			

	# Get input and apply movement if not dashing
	if not is_dashing:
		get_input(delta)

	# Move the character
	move_and_slide()

func connect_to_powerups():
	# Find all powerups in the scene
	var powerups = get_tree().get_nodes_in_group("powerup")
	
	# Connect to powerup collection signals
	for powerup in powerups:
		if powerup.has_method("_on_powerup_collected"):
			powerup._on_powerup_collected.connect(_on_powerup_collected)

# Called when powerup is collected
func _on_powerup_collected(power_type: String, power_value: int) -> void:
	# Handle different powerup types
	match power_type:
		"Jump":
			max_jumps += power_value  # Add to existing jumps instead of replacing
			jumps_left = max_jumps
		"Dash":
			max_dash = power_value
			num_dash = max_dash
			dash_able = true  # Enable dash ability
		_:
			pass

func has_item(item_name: String) -> bool:
	return item_name in held_items

func pick_up_item(item):
	# Check if already picking up an item
	if is_picking_up:
		return
	
	# Close any open read dialog first
	if is_reading_book:
		close_read_dialog()
		# Manually hide the close button to be sure
		if close_button and close_button.visible:
			close_button.visible = false
	
	# Don't try to pick up items that don't exist or are already held
	if not is_instance_valid(item) or held_items.has(item):
		return
		
	is_picking_up = true  # Set flag to prevent multiple pickups
	
	# Block movement only during pickup animation
	var was_movement_enabled = can_move
	can_move = false
	
	# Play pickup animation
	$player_anim.play("pickup item")
	
	# Wait for the animation to finish before picking up the item
	await $player_anim.animation_finished
	
	# Check if the item still exists and has a parent
	if is_instance_valid(item) and item.get_parent():
		item.get_parent().remove_child(item)
		
		# Find the next available slot in the hotbar
		var next_available_slot = selected_item_index
		if hotbar and hotbar.items[selected_item_index] != null:
			# Current slot is full, find the next available slot
			for i in range(selected_item_index + 1, hotbar.max_slots):
				if hotbar.items[i] == null:
					next_available_slot = i
					break
			
			# If no slot found after the current one, check from the beginning
			if next_available_slot == selected_item_index:
				for i in range(0, selected_item_index):
					if hotbar.items[i] == null:
						next_available_slot = i
						break
			
			# If still no slot found, the hotbar is full
			if next_available_slot == selected_item_index and hotbar.items[selected_item_index] != null:
				is_picking_up = false  # Reset flag
				can_move = was_movement_enabled  # Restore movement state
				return
		
		# Add to held items
		held_items.append(item)
		selected_item_index = next_available_slot
		
		# Update hotbar
		if hotbar:
			# Get the item's sprite texture from the Sprite2D node
			var sprite_node = item.get_node_or_null("Sprite2D")
			if sprite_node:
				var item_texture = sprite_node.texture
				hotbar.add_item(item_texture, selected_item_index)
		
		# Add the item to the TorchHolder
		$TorchHolder.add_child(item)
		item.position = Vector2.ZERO
		item.visible = true
		
		# Keep track of the original scale value for later use
		if not item.has_meta("original_scale_stored"):
			item.set_meta("original_scale_stored", item.scale)
		
		# Set appropriate scale and rotation for torch
		if item.name.contains("Torch"):
			# For torch, use a consistent scale of 1.0
			item.scale = Vector2(1.0, 1.0)
			item.rotation = 0
			
			# Maintain the smaller light scale for torch
			var light = item.get_node_or_null("PointLight2D")
			if light:
				light.scale = Vector2(0.25, 0.25)  # Keep the smaller light scale
				light.energy = 0.8  # Keep reduced energy
				light.texture_scale = 0.5  # Maintain smaller texture scale
		else:
			# For all other items, keep original scale
			item.scale = item.original_scale
			item.rotation = 0
		
		# Update held item display
		update_held_item()
	
	# Reset animation state
	$player_anim.play("RESET")
	
	# Restore movement to previous state
	can_move = was_movement_enabled
	
	# Reset the pickup flag
	is_picking_up = false
	
	# Debug message to confirm pickup completed
	print("Pickup completed, movement restored to: ", can_move)

func drop_item(perma: bool):
	if held_items.is_empty():
			pass
			
	else:
		var item_to_drop = held_items[selected_item_index]
		if not held_items.is_empty() and is_on_floor() and not is_picking_up:  
			# Play throw animation only once
			if not $player_anim.is_playing():
				$player_anim.play("throw item")
			
			# Wait for the animation to finish before dropping the item
			await $player_anim.animation_finished
			
			# Ensure we don't continue if the player no longer has items
			if held_items.is_empty():
				return
			
			if perma:
				item_to_drop.queue_free()
			else:
			
				# Get the World node
				var world = get_node("/root/World")
				if world:
					# Store original properties for torch
					var is_torch = item_to_drop.name.contains("Torch")
					var stored_original_scale = item_to_drop.original_scale
					if item_to_drop.has_meta("original_scale_stored"):
						stored_original_scale = item_to_drop.get_meta("original_scale_stored")
				
					# Remove from TorchHolder first
					if item_to_drop.get_parent() == $TorchHolder:
						$TorchHolder.remove_child(item_to_drop)
				
					# Add to world and set position
					world.add_child(item_to_drop)
				
					# Position relative to the World node
					var drop_position = global_position  # Start with player's global position
				
					# Convert to World's local space
					var world_local_pos = world.to_local(drop_position)
				
					# Set drop position in World's local space
					drop_position = world_local_pos
					# Adjust Y position to be at ground level
					drop_position.y += 20  # Small offset to place on ground
					drop_position.x += 10  # Small offset to the right
				
					# Set the item's position and scale
					item_to_drop.position = drop_position
				
					# Reset scale and rotation based on item type
					if is_torch:
						# For torch, use a consistent scale of 1.0
						item_to_drop.scale = Vector2(1.0, 1.0)
						item_to_drop.rotation = 0  # Reset rotation to upright
					
						# Maintain the smaller light scale for torch
						var light = item_to_drop.get_node_or_null("PointLight2D")
						if light:
							light.scale = Vector2(0.25, 0.25)  # Keep the smaller light scale
							light.energy = 0.8  # Keep reduced energy
							light.texture_scale = 0.5  # Maintain smaller texture scale
					else:
						# For other items, use their original scale
						item_to_drop.scale = stored_original_scale
						item_to_drop.rotation = 0
				
					item_to_drop.can_be_picked_up = true
				
					# Call the _on_dropped function on the item
					if item_to_drop.has_method("_on_dropped"):
						item_to_drop._on_dropped()
				
					# Update hotbar first
					if hotbar:
						hotbar.remove_item(selected_item_index)
						num_items -= 1
				
					# Remove from held items
					held_items.remove_at(selected_item_index)
				
					# Update selection and held item
					if held_items.is_empty():
						selected_item_index = 0
					else:
						selected_item_index = min(selected_item_index, held_items.size() - 1)
					update_held_item()
				
					# Reset TorchHolder position and rotation to consistent values
					$TorchHolder.position = Vector2(26, 8)
					$TorchHolder.scale = Vector2(0.5, 0.5)  # Set a consistent scale
					$TorchHolder.rotation = deg_to_rad(25)  # Set a consistent rotation of 25 degrees
					$TorchHolder.set_skew(0)
				else:
					# Reset animation state even if we couldn't drop the item
					$player_anim.play("RESET")
		else:
			if held_items.is_empty():
				pass  # No items to drop
			if not is_on_floor():
				pass  # Player is not on floor

func set_can_move(state):
	can_move = state

func _input(event):
	# Check if player is trying to read a book
	if event.is_action_pressed("pick_up") and not is_reading_book and not held_items.is_empty():
		var current_item = held_items[selected_item_index]
		if is_instance_valid(current_item):
			# Check if the item is a book and has content to read
			var is_book = current_item.name.contains("Autobiography") or current_item.name.contains("Book")
			if is_book and current_item.has_meta("book_content"):
				var content = current_item.get_meta("book_content")
				open_read_dialog(content)
				return
	
	# Handle inventory item selection with numpad (more reliable)
	if event.is_action_pressed("number_1"):
		switch_item(0)
	elif event.is_action_pressed("number_2"):
		switch_item(1)
	elif event.is_action_pressed("number_3"):
		switch_item(2)
	elif event.is_action_pressed("number_4"):
		switch_item(3)
	elif event.is_action_pressed("number_5"):
		switch_item(4)
	elif event.is_action_pressed("set_down"):
		drop_item(false)

func switch_item(index: int):
	if index >= 0 and index < held_items.size():
		selected_item_index = index
		update_held_item()

func update_held_item():
	# Clear TorchHolder
	for child in $TorchHolder.get_children():
		$TorchHolder.remove_child(child)
	
	# Set TorchHolder to consistent values
	$TorchHolder.position = Vector2(26, 8)
	$TorchHolder.scale = Vector2(0.5, 0.5)  # Set a consistent scale
	$TorchHolder.rotation = deg_to_rad(25)  # Set a consistent rotation of 25 degrees
	$TorchHolder.set_skew(0)
	
	# If we have items and a valid selection
	if not held_items.is_empty() and selected_item_index < held_items.size():
		var selected_item = held_items[selected_item_index]
		
		# Get the original scale from meta
		var stored_original_scale = selected_item.original_scale
		if selected_item.has_meta("original_scale_stored"):
			stored_original_scale = selected_item.get_meta("original_scale_stored")
		
		$TorchHolder.add_child(selected_item)
		selected_item.position = Vector2.ZERO
		selected_item.visible = true
		
		# Set appropriate scale and rotation for torch
		if selected_item.name.contains("Torch"):
			# For torch, use a consistent scale of 1.0
			selected_item.scale = Vector2(1.0, 1.0)
			selected_item.rotation = 0
			
			# Maintain the smaller light scale for torch
			var light = selected_item.get_node_or_null("PointLight2D")
			if light:
				light.scale = Vector2(0.25, 0.25)  # Keep the smaller light scale
				light.energy = 0.8  # Keep reduced energy
				light.texture_scale = 0.5  # Maintain smaller texture scale
		else:
			# For other items, use their original scale
			selected_item.scale = stored_original_scale
			selected_item.rotation = 0
		
		# Update hotbar selection
		if hotbar:
			hotbar.set_selected(selected_item_index)

func _process(delta):
	# Close dialog if escape is pressed
	if is_reading_book and Input.is_action_just_pressed("ui_cancel"):
		close_read_dialog()
		
		# Ensure the close button is hidden
		if close_button:
			close_button.visible = false
		
		# Reset movement control after closing
		if not is_picking_up and not is_dashing:
			can_move = true
	
	# Process pickups with direct input check
	if Input.is_action_just_pressed("pick_up"):
		process_pickup_input()

# Create an area detector for detecting nearby items
func create_pickup_detector():
	if has_node("PickupDetector"):
		return # Already exists
		
	var detector = Area2D.new()
	detector.name = "PickupDetector"
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 60  # Detection radius
	collision.shape = shape
	
	detector.add_child(collision)
	add_child(detector)

# Separate function to handle pickup input
func process_pickup_input():
	# First check if we're looking at a book in inventory
	if not is_reading_book and not held_items.is_empty():
		var current_item = held_items[selected_item_index]
		if is_instance_valid(current_item):
			# Check if the item is a book and has content to read
			var is_book = current_item.name.contains("Autobiography") or current_item.name.contains("Book")
			if is_book and current_item.has_meta("book_content"):
				var content = current_item.get_meta("book_content")
				open_read_dialog(content)
				return
	
	# Check for items to pick up using our detector area
	var detector = get_node_or_null("PickupDetector")
	if detector:
		for area in detector.get_overlapping_areas():
			if area.is_in_group("item") and area.has_method("_process"):
				# The item will handle pickup logic in its own _process method
				return

# Function to remove powerups when entering dining room
func remove_powerups() -> void:
	# Reset jumps to base value
	max_jumps = 1
	jumps_left = max_jumps
	
	# Remove dash ability
	dash_able = false
	max_dash = 0
	num_dash = 0

# New function to handle direct collision with powerups
func _on_powerup_collected_directly(body, powerup):
	if body == self and not collected_powerups.has(powerup.power_type):
		if powerup.has_method("_on_powerup_collected"):
			powerup._on_powerup_collected(powerup.power_type, powerup.power_value)
			collected_powerups.append(powerup.power_type)
			powerup.queue_free()
			
