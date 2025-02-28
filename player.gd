extends CharacterBody2D

# Movement variables
var max_speed = 200
var run_speed = 500
var acceleration = 1500
var deceleration = 1200
var air_control = 600  # Less control in the air
var jump_force = -500  
var gravity = 1500
var jump_release_reduction = 0.5  # Reduces jump height if released early
var sprint_jump_multiplier = 1.15  # Multiplier for carrying sprint momentum into jumps
var inventory = [] 

# Velocity tracking
var target_speed = 0  

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
	var is_running = Input.is_action_pressed("run") and is_on_floor()  
	var is_jumping = Input.is_action_just_pressed("jump")
	var is_releasing_jump = Input.is_action_just_released("jump")
	
	# Set target speed based on walking or running
	target_speed = (run_speed if is_running else max_speed) * direction
	
	# Adjust acceleration/deceleration based on ground/air
	@warning_ignore("integer_division")
	var accel = acceleration if is_on_floor() else air_control
	var decel = deceleration if is_on_floor() else air_control / 2
	
	# Accelerate towards target speed
	if direction != 0:
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)
	
	# Jumping logic
	if is_jumping and jumps_left > 0:
		# Carry sprint momentum into the jump
		if is_running:
			velocity.x *= sprint_jump_multiplier  # Increase jump distance when sprinting

		# Apply additional horizontal momentum if jumping mid-air
		if not is_on_floor():
			velocity.x *= 1.1  # Slight mid-air boost for a smoother feel

		# Apply jump force
		velocity.y = jump_force  

		jumps_left -= 1  # Reduce available jumps

	# Reduce jump height if released early
	if is_releasing_jump and velocity.y < 0:
		velocity.y *= jump_release_reduction

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		if velocity.y < 0:  # Rising
			velocity.y += gravity * 0.8 * delta  # Less gravity when moving up
		else:  # Falling
			velocity.y += gravity * delta  # Normal gravity when falling
	else:
		# Reset jumps when on the ground
		jumps_left = max_jumps  

	# Get input and apply movement
	get_input(delta)
	
	# Move the character
	move_and_slide()

func on_power_up_collected(power_type: Variant) -> void:
	match power_type:
		"Jump":
			max_jumps += 1
			jumps_left = max_jumps  # Update available jumps immediately

func has_item(item_name: String) -> bool:
	return item_name in inventory
	
func set_can_move(state):
	can_move = state
