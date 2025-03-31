extends CharacterBody2D

# Movement variables
var max_speed = 400
var dash_speed = 1000  # Speed for dashing
var acceleration = 1000
var deceleration = 1000
var air_control = 1100  # Less control in the air
var jump_force = -800  
var gravity = 1750
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

func _ready():
	jumps_left = max_jumps  # Ensure jumps are initialized correctly
	add_to_group("player")

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
		#print("pushed dash")
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

func on_power_up_collected(power_type: Variant) -> void:
	match power_type:
		"Jump":
			max_jumps += 1
			jumps_left = max_jumps  
		"Dash":
			dash_able = true
			max_dash += 1
			num_dash = max_dash
			

func has_item(item_name: String) -> bool:
	return item_name in inventory

var held_item = null

@onready var hotbar = get_tree().current_scene.find_child("Hotbar", true, false)
var num_items := 0

func pick_up_item(item):
	#if held_item == null:
		#held_item = item
		item.can_be_picked_up = false
		item.get_parent().remove_child(item)
		if num_items == 0:
			$TorchHolder.add_child(item)
		item.position = Vector2.ZERO
		if hotbar:
			var sprite = item.get_node_or_null("Sprite2D")
			if sprite:
				hotbar.add_item(sprite.texture, num_items)
				num_items += 1

func drop_item():
	#held_item != null and
	if  is_on_floor():  
		# Play throw animation
		$player_anim.play("throw item")
		
		# Wait for the animation to finish before dropping the item
		await $player_anim.animation_finished
		
		#held_item.can_be_picked_up = true
		var level = get_tree().current_scene.find_child("Level", true, false)
		if level:
			$TorchHolder.remove_child(held_item)
			level.add_child(held_item)
			held_item.global_position = global_position + Vector2(60, 40)  # Offset slightly forward
			held_item.global_rotation_degrees = 90
			held_item.scale = Vector2(0.9,0.9)
			held_item.set_skew(0)
			$TorchHolder.position = Vector2(26, 8)
			$TorchHolder.global_rotation_degrees = -65
			$TorchHolder.global_scale = Vector2(1,1)
			$TorchHolder.set_skew(0)
		if hotbar:
			var sprite = held_item.get_node_or_null("Sprite2D")
			if sprite:
				hotbar.remove_item(sprite.texture)
				num_items -= 1

		# Reset `held_item` and ensure `TorchHolder` is empty
		held_item = null
		for child in $TorchHolder.get_children():
			$TorchHolder.remove_child(child)

func set_can_move(state):
	can_move = state
