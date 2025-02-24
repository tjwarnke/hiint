extends CharacterBody2D

# Movement variables
var max_speed = 200
var run_speed = 400
var acceleration = 1500
var deceleration = 1200
var air_control = 600  # Less control in the air
var jump_force = -600  
var gravity = 1400
var jump_release_reduction = 0.5  # Reduces jump height if released early
var inventory = []  

# Velocity tracking
var target_speed = 0  

@export var max_jumps: int = 1  
var jumps_left: int
var item_type = ""

var has_jumped = false  # Tracks if player has jumped at least once

func _ready():
	jumps_left = max_jumps
	
func get_input(delta):
	var direction = Input.get_axis("left", "right")  
	var is_running = Input.is_action_pressed("run") and is_on_floor()  # Sprint only if on the ground
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
		# Prevent first jump unless on ground
		if not has_jumped and not is_on_floor():
			return  

		velocity.y = jump_force
		jumps_left -= 1
		has_jumped = true  # Set flag since player has jumped

	# Reduce jump height if released early
	if is_releasing_jump and velocity.y < 0:
		velocity.y *= jump_release_reduction

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Reset jumps when on the ground
		jumps_left = max_jumps
		has_jumped = false  # Allow jumping again from ground

	# Get input and apply movement
	get_input(delta)
	
	# Move the character
	move_and_slide()

func on_power_up_collected(power_type: Variant) -> void:
	match power_type:
		"Jump":
			max_jumps += 1
			jumps_left = max_jumps
			
			

func has_item(item_name: String) -> bool:
	return item_name in inventory
