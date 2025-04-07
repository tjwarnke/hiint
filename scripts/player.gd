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

@onready var hotbar = get_node("/root/World/Camera2D/Hotbar")
var num_items := 0
var selected_item_index := 0
var held_items = []

func _ready():
	jumps_left = max_jumps  # Ensure jumps are initialized correctly
	add_to_group("player")

	
	# Connect to powerup signals
	for powerup in get_tree().get_nodes_in_group("powerup"):
		print("Found powerup: ", powerup)  # Debug print
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
		print("Starting dash!")  # Debug print
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
	item.can_be_picked_up = false
	item.get_parent().remove_child(item)
	
	# Add to held items array
	held_items.append(item)
	
	# If this is the first item, select it
	if held_items.size() == 1:
		selected_item_index = 0
		update_held_item()
	
	if hotbar:
		var sprite = item.get_node_or_null("Sprite2D")
		if sprite:
			print("Adding item to hotbar at index: ", num_items)  # Debug print
			hotbar.add_item(sprite.texture, num_items)
			num_items += 1
			print("New num_items: ", num_items)  # Debug print

func drop_item():
	print("Attempting to drop item")  # Debug print
	if not held_items.is_empty() and is_on_floor():  
		print("Can drop item - Held items: ", held_items.size())  # Debug print
		# Play throw animation
		print("Playing throw animation")  # Debug print
		$player_anim.play("throw item")
		
		# Wait for the animation to finish before dropping the item
		print("Waiting for animation to finish")  # Debug print
		await $player_anim.animation_finished
		print("Animation finished")  # Debug print
		
		# Get the World node
		var world = get_node("/root/World")
		if world:
			var item_to_drop = held_items[selected_item_index]
			print("Dropping item at index: ", selected_item_index)  # Debug print
			
			# Remove from TorchHolder first
			if item_to_drop.get_parent() == $TorchHolder:
				print("Removing from TorchHolder")  # Debug print
				$TorchHolder.remove_child(item_to_drop)
			
			# Add to world and set position
			world.add_child(item_to_drop)
			print("Added item to world")  # Debug print
			
			# Set the item's position and make it pickable again
			item_to_drop.position = global_position + Vector2(10, -10)
			item_to_drop.can_be_picked_up = true
			print("Set item position and made it pickable")  # Debug print
			
			# Update hotbar first
			if hotbar:
				print("Updating hotbar - Removing item at index: ", selected_item_index)  # Debug print
				hotbar.remove_item(selected_item_index)
				num_items -= 1
				print("New num_items: ", num_items)  # Debug print
			
			# Remove from held items
			held_items.remove_at(selected_item_index)
			print("Remaining held items: ", held_items.size())  # Debug print
			
			# Update selection and held item
			if held_items.is_empty():
				selected_item_index = 0
			else:
				selected_item_index = min(selected_item_index, held_items.size() - 1)
			update_held_item()
			print("Updated selection and held item")  # Debug print
			
			# Reset TorchHolder position and rotation
			$TorchHolder.position = Vector2(26, 8)
			$TorchHolder.global_rotation_degrees = -65
			$TorchHolder.global_scale = Vector2(1, 1)
			$TorchHolder.set_skew(0)
			print("Reset TorchHolder")  # Debug print
		else:
			print("World node not found!")  # Debug print
			# Reset animation state even if we couldn't drop the item
			$player_anim.play("RESET")
	else:
		if held_items.is_empty():
			print("No items to drop")  # Debug print
		if not is_on_floor():
			print("Player is not on floor")  # Debug print

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
	
	# If we have items and a valid selection
	if not held_items.is_empty() and selected_item_index < held_items.size():
		var selected_item = held_items[selected_item_index]
		$TorchHolder.add_child(selected_item)
		selected_item.position = Vector2.ZERO
		selected_item.visible = true
		
		# Update hotbar selection
		if hotbar:
			hotbar.set_selected(selected_item_index)
