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

@export var max_jumps: int = 1  
var jumps_left: int
var item_type = ""

var can_move = true
var is_picking_up = false  # Flag to prevent multiple simultaneous pickups

@onready var hotbar = get_node("/root/World/Camera2D/Control/Hotbar")
var num_items := 0
var selected_item_index := 0
var held_items = []

func _ready():
	jumps_left = max_jumps  # Ensure jumps are initialized correctly
	add_to_group("player")

	
	# Connect to powerup signals
	for powerup in get_tree().get_nodes_in_group("powerup"):
		powerup.collected.connect(_on_powerup_collected)

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

func _on_powerup_collected(power_type: String, power_value: int) -> void:
	match power_type:
		"Jump":
			max_jumps += power_value
			jumps_left = max_jumps
		"Dash":
			dash_able = true
			max_dash += power_value
			num_dash = max_dash

func has_item(item_name: String) -> bool:
	return item_name in inventory

func pick_up_item(item):
	print("PLAYER DEBUG: Starting pick_up_item with item: ", item.name)
	print("PLAYER DEBUG: Item scale before pickup: ", item.scale)
	
	# Check if already picking up an item
	if is_picking_up:
		print("PLAYER DEBUG: Already picking up an item, ignoring request")
		return
		
	if not held_items.has(item):
		is_picking_up = true  # Set flag to prevent multiple pickups
		print("PLAYER DEBUG: Item not already held, proceeding with pickup")
		# Play pickup animation
		$player_anim.play("pickup item")
		print("PLAYER DEBUG: Started pickup animation")
		
		# Wait for the animation to finish before picking up the item
		await $player_anim.animation_finished
		print("PLAYER DEBUG: Pickup animation finished")
		
		# Check if the item still exists and has a parent
		if is_instance_valid(item) and item.get_parent():
			print("PLAYER DEBUG: Removing item from parent: ", item.get_parent().name)
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
			if next_available_slot == selected_item_index:
				print("PLAYER DEBUG: Hotbar is full, cannot pick up item")
				is_picking_up = false  # Reset flag
				return
		
		# Add to held items
		held_items.append(item)
		selected_item_index = next_available_slot
		print("PLAYER DEBUG: Added item to held_items at index: ", selected_item_index)
		
		# Update hotbar
		if hotbar:
			print("PLAYER DEBUG: Updating hotbar with item at index: ", selected_item_index)
			# Get the item's sprite texture from the Sprite2D node
			var sprite_node = item.get_node_or_null("Sprite2D")
			if sprite_node:
				var item_texture = sprite_node.texture
				print("PLAYER DEBUG: Item texture: ", item_texture)
				hotbar.add_item(item_texture, selected_item_index)
			else:
				print("PLAYER DEBUG: No Sprite2D node found on item")
		else:
			print("PLAYER DEBUG: No hotbar found!")
		
		# Add the item to the TorchHolder
		$TorchHolder.add_child(item)
		item.position = Vector2.ZERO
		item.visible = true
		
		# Set appropriate scale and rotation for torch
		if item.name.contains("Torch"):
			print("PLAYER DEBUG: Setting torch scale before: ", item.scale)
			# For torch, use a consistent scale of 1.0
			item.scale = Vector2(1.0, 1.0)
			print("PLAYER DEBUG: Setting torch scale after: ", item.scale)
			item.rotation = 0
			
			# Reset the PointLight2D scale to ensure proper light shape
			var light = item.get_node_or_null("PointLight2D")
			if light:
				light.scale = Vector2(1.0, 1.0)  # Set light scale to 1.0, 1.0
				print("PLAYER DEBUG: Light scale set to: ", light.scale)
		else:
			# For other items, use a standard scale
			item.scale = Vector2(0.25, 0.25)
			item.rotation = 0
		
		# Update held item display
		update_held_item()
		
		# Reset animation state
		$player_anim.play("RESET")
		print("PLAYER DEBUG: Reset animation state")
		print("PLAYER DEBUG: Final item scale after pickup: ", item.scale)
		
		# Reset the pickup flag
		is_picking_up = false
	else:
		print("PLAYER DEBUG: Item already held, skipping pickup")

func drop_item():
	if not held_items.is_empty() and is_on_floor() and not is_picking_up:  
		print("PLAYER DEBUG: Starting drop_item")
		# Play throw animation
		$player_anim.play("throw item")
		
		# Wait for the animation to finish before dropping the item
		await $player_anim.animation_finished
		print("PLAYER DEBUG: Throw animation finished")
		
		# Get the World node
		var world = get_node("/root/World")
		if world:
			var item_to_drop = held_items[selected_item_index]
			print("PLAYER DEBUG: Item to drop scale before: ", item_to_drop.scale)
			
			# Store original properties for torch
			var is_torch = item_to_drop.name.contains("Torch")
			var _original_scale = item_to_drop.scale
			var _original_rotation = item_to_drop.rotation
			print("PLAYER DEBUG: Original scale stored: ", _original_scale)
			
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
				print("PLAYER DEBUG: Setting torch scale before drop: ", item_to_drop.scale)
				# For torch, use a consistent scale of 1.0
				item_to_drop.scale = Vector2(1.0, 1.0)
				print("PLAYER DEBUG: Setting torch scale after drop: ", item_to_drop.scale)
				item_to_drop.rotation = 0  # Reset rotation to upright
				
				# Reset the PointLight2D scale to ensure proper light shape
				var light = item_to_drop.get_node_or_null("PointLight2D")
				if light:
					light.scale = Vector2(1.0, 1.0)  # Set light scale to 1.0, 1.0
					print("PLAYER DEBUG: Light scale set to: ", light.scale)
			else:
				# For other items, use a standard scale
				item_to_drop.scale = Vector2(0.25, 0.25)  # Half of 0.5 to compensate for World's scale
				item_to_drop.rotation = 0
			
			item_to_drop.can_be_picked_up = true
			
			# Call the _on_dropped function on the item
			if item_to_drop.has_method("_on_dropped"):
				print("PLAYER DEBUG: Calling _on_dropped on item")
				item_to_drop._on_dropped()
				print("PLAYER DEBUG: Item scale after _on_dropped: ", item_to_drop.scale)
			
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
			print("PLAYER DEBUG: Final item scale after drop: ", item_to_drop.scale)
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
		drop_item()

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
		
		# Store the current scale before adding to TorchHolder
		var _current_scale = selected_item.scale
		
		$TorchHolder.add_child(selected_item)
		selected_item.position = Vector2.ZERO
		selected_item.visible = true
		
		# Set appropriate scale and rotation for torch
		if selected_item.name.contains("Torch"):
			# For torch, use a consistent scale of 1.0
			selected_item.scale = Vector2(1.0, 1.0)
			selected_item.rotation = 0
			
			# Reset the PointLight2D scale to ensure proper light shape
			var light = selected_item.get_node_or_null("PointLight2D")
			if light:
				light.scale = Vector2(1.0, 1.0)  # Set light scale to 1.0, 1.0
		else:
			# For other items, use a standard scale
			selected_item.scale = Vector2(0.25, 0.25)
			selected_item.rotation = 0
		
		# Update hotbar selection
		if hotbar:
			hotbar.set_selected(selected_item_index)
