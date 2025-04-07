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
	if not held_items.has(item):
		# Play pickup animation
		$player_anim.play("pickup item")
		
		# Wait for the animation to finish before picking up the item
		await $player_anim.animation_finished
		
		# Remove from parent first
		if item.get_parent():
			item.get_parent().remove_child(item)
		
		# Add to held items
		held_items.append(item)
		selected_item_index = held_items.size() - 1
		
		# Update hotbar
		if hotbar:
			hotbar.add_item(item, selected_item_index)
		
		# Update held item
		update_held_item()
		
		# Reset animation state
		$player_anim.play("RESET")

func drop_item():
	if not held_items.is_empty() and is_on_floor():  
		# Play throw animation
		$player_anim.play("throw item")
		
		# Wait for the animation to finish before dropping the item
		await $player_anim.animation_finished
		
		# Get the World node
		var world = get_node("/root/World")
		if world:
			var item_to_drop = held_items[selected_item_index]
			
			# Store original properties for torch
			var is_torch = item_to_drop.name.contains("Torch")
			var original_scale = item_to_drop.scale
			var original_rotation = item_to_drop.rotation
			
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
				# For torch, use the original scale from the torch.tscn file
				# Since World has a scale of 2.0, we need to compensate
				item_to_drop.scale = Vector2(0.471256, 0.653965)  # Half of the original scale to compensate for World's scale
				item_to_drop.rotation = 0  # Reset rotation to upright
				
				# Reset the PointLight2D scale to ensure proper light shape
				var light = item_to_drop.get_node_or_null("PointLight2D")
				if light:
					light.scale = Vector2(1.429, 1)  # Original light scale from torch.tscn
			else:
				# For other items, use a standard scale
				item_to_drop.scale = Vector2(0.25, 0.25)  # Half of 0.5 to compensate for World's scale
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
		if hotbar:
			hotbar.set_selected(index)

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
		var current_scale = selected_item.scale
		
		$TorchHolder.add_child(selected_item)
		selected_item.position = Vector2.ZERO
		selected_item.visible = true
		
		# Set appropriate scale and rotation for torch
		if selected_item.name.contains("Torch"):
			# For torch, use a consistent scale that matches the dropped state
			# This ensures consistency between dropped and held states
			selected_item.scale = Vector2(0.471256, 0.653965)  # Same scale as when dropped
			selected_item.rotation = 0
			
			# Reset the PointLight2D scale to ensure proper light shape
			var light = selected_item.get_node_or_null("PointLight2D")
			if light:
				light.scale = Vector2(1.429, 1)  # Original light scale from torch.tscn
		else:
			# For other items, use a standard scale
			selected_item.scale = Vector2(0.25, 0.25)
			selected_item.rotation = 0
		
		# Update hotbar selection
		if hotbar:
			hotbar.set_selected(selected_item_index)
