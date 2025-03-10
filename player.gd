extends CharacterBody2D

# Movement variables
var max_speed = 400
var dash_speed = 1000  # Speed for dashing
var acceleration = 1000
var deceleration = 1000
var air_control = 1100  # Less control in the air
var jump_force = -700  
var gravity = 1500
var fast_fall_gravity = 5000  # Stronger gravity when fast-falling
var jump_release_reduction = 0.5  # Reduces jump height if released early
var inventory = []  
var torch = null
var dash_able = false
var is_dashing = false
var dash_time = 0.15  # Duration of dash
var dash_timer = 0.0

# Velocity tracking
var target_speed = 0  
var is_fast_falling = false  # Track fast-fall state

@export var max_jumps: int = 1  
var jumps_left: int
var item_type = ""

func _ready():
	jumps_left = max_jumps  # Ensure jumps are initialized correctly

func get_input(delta):
	var direction = Input.get_axis("left", "right")  
	var is_jumping = Input.is_action_just_pressed("jump")
	var is_releasing_jump = Input.is_action_just_released("jump")
	var is_pressing_fast_fall = Input.is_action_just_pressed("fast_fall")  
	var is_dashing_pressed = Input.is_action_just_pressed("dash")  # Dash key

	# Handle dashing
	if dash_able and is_dashing_pressed and not is_dashing:
		print("pushed dash")
		is_dashing = true
		dash_timer = dash_time
		velocity.x = dash_speed * direction  # Dash in facing direction

	# If not dashing, apply normal movement
	if not is_dashing:
		target_speed = max_speed * direction
		var accel = acceleration if is_on_floor() else air_control
		var decel = deceleration if is_on_floor() else air_control / 2
		
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
	print(power_type)
	match power_type:
		"Jump":
			max_jumps += 1
			jumps_left = max_jumps  
		"Dash":
			dash_able = true

func has_item(item_name: String) -> bool:
	return item_name in inventory

func pick_up_torch(torch_instance):
	if torch == null: 
		torch = torch_instance
		torch.can_be_picked_up = false
		torch.get_parent().remove_child(torch)
		$TorchHolder.add_child(torch)
		torch.position = Vector2.ZERO
		
func drop_torch():
	if torch and is_on_floor():
		var level = get_tree().current_scene.find_child("Level", true, false)
		if level:
			$TorchHolder.remove_child(torch)
			level.add_child(torch)
			torch.position = global_position + Vector2(10, -10)  
			torch.can_be_picked_up = true
			torch = null
