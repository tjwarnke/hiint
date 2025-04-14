extends Node2D

#TODO: You cant take your powerups with you into dining
#TODO: powerup pickup gives text to tell you what they do
# Load player scene
var PlayerScene = preload("res://scenes/Player.tscn")  
var PauseMenuScene = preload("res://scenes/pause_menu.tscn")  
var player
var pause_menu

# Nodes
@onready var spawn = get_node_or_null("Spawn")
@onready var camera = $Camera2D  
@onready var jumpscare = $Camera2D/Jumpscare
@onready var jumpscare_timer = $Camera2D/Timer  
@onready var jumpscare_noise = $Camera2D/AudioStreamPlayer
@onready var darkness = $Camera2D/CanvasModulate
@onready var ambient_noise = preload("res://scenes/ambient_noise.tscn").instantiate()
@onready var world_attach_node = $Attach  # Rename to clarify this is the world's attach node

# Dining room nodes (will be set after scene is loaded)
var dining_wall = null
var dining_threshold = null
var wall_fall = null
var library_threshold = null

var moving_player = false
var move_distance = 500
var move_speed = 100.0
var camera_smooth_speed = 0.0001  # Adjust this value for smoother/slower movement

func _ready():
	spawn_player()
	initialize_game_state()
	
	# Add pause menu
	pause_menu = PauseMenuScene.instantiate()
	# Add to the root viewport to ensure it's above everything
	get_tree().root.add_child(pause_menu)
	
	# Initialize camera immediately after player spawning
	if player and camera:
		set_camera_target()
	else:
		call_deferred("set_camera_target")
	
	# Initialize dining room components
	dining_threshold = $DiningRoom/dining_bounds
	if dining_threshold:
		dining_threshold.body_entered.connect(_on_dining_threshold_entered)
	else:
		push_error("Dining threshold not found!")
		
	# Initialize library threshold - try multiple potential paths
	var found_library_threshold = false
	var potential_paths = [
		"Library/LibraryThreshold",
		"Library/library_bounds",
		"Library/threshold",
		"Library/bounds"
	]
	
	for path in potential_paths:
		library_threshold = get_node_or_null(path)
		if library_threshold:
			found_library_threshold = true
			configure_library_threshold(library_threshold)
			library_threshold.body_entered.connect(_on_library_threshold_entered)
			break
	
	if not found_library_threshold:
		var lib_node = get_node_or_null("Library")
		if lib_node:
			# Recursively search for any Area2D that might be the threshold
			library_threshold = find_area2d_in_children(lib_node)
			if library_threshold:
				configure_library_threshold(library_threshold)
				library_threshold.body_entered.connect(_on_library_threshold_entered)
				found_library_threshold = true
	
	if not found_library_threshold:
		push_error("Library threshold not found! Camera transitions won't work.")
		
	wall_fall = $DiningRoom/WallFall
	if not wall_fall:
		push_error("Wall fall animation not found!")

func _process(delta):
	# Handle input
	handle_input()
	
	# Handle player movement
	handle_player_movement(delta)
	
	# Ensure camera is following player correctly
	if player and camera:
		# Every 30 frames, verify camera is following player correctly
		if Engine.get_process_frames() % 30 == 0:
			var distance = abs(camera.position.x - player.position.x)
			if distance > 300 and not moving_player:
				camera.position.x = player.position.x
				if camera.in_library_area:
					camera.position.y = player.position.y
				else:
					camera.position.y = camera.fixed_y

func set_camera_target():
	if player:
		camera.player = player
		camera.position = Vector2(player.position.x, camera.fixed_y)
		# Force update to match player position immediately
		get_tree().process_frame
	else:
		push_error("Player is missing when setting camera target!")
		
func initialize_game_state():
	darkness.show()
	$cabin/Torch.show()
	jumpscare_timer.timeout.connect(hide_jumpscare)  
	MainMusic.fade_out(MainMusic)

	# Add ambient noise
	add_child(ambient_noise)
	

func handle_input():
	if Input.is_action_just_pressed("p"):
		show_jumpscare()
		jumpscare_noise.play()

func handle_player_movement(delta):
	if moving_player:
		player.position.x += move_speed * delta
		move_distance -= move_speed * delta
		if move_distance <= 0:
			moving_player = false  
			drop_wall()


func show_jumpscare():
	jumpscare.show()
	jumpscare_timer.start()

func hide_jumpscare():
	jumpscare.hide()

	
func spawn_player():
	player = PlayerScene.instantiate()
	if not player:
		push_error("Failed to instantiate player scene")
		return

	add_child(player)

	# Ensure spawn exists before setting position
	if not spawn:
		push_error("Spawn node is missing!")
		return
	player.global_position = spawn.global_position
	
	# Set camera settings
	if camera:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		camera.drag_horizontal_enabled = true
		camera.drag_left_margin = 0.1
		camera.drag_top_margin = 0.1
		camera.drag_right_margin = 0.1
		camera.drag_bottom_margin = 0.1

func initialize_camera():
	camera.position = Vector2(player.position.x, camera.fixed_y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.drag_horizontal_enabled = true
	camera.drag_left_margin = 0.1
	camera.drag_top_margin = 0.1
	camera.drag_right_margin = 0.1
	camera.drag_bottom_margin = 0.1
	
func on_power_up(power_type: String, power_value: int) -> void:
	if player:
		player._on_powerup_collected(power_type, power_value)

func _on_dining_threshold_entered(body):
	if body == player:
		await wait_until_grounded()  # Ensure player is stable before continuing
		update_camera_bounds()  # Update camera dynamically instead of moving
		move_player_slowly()
		ambient_noise.on_dining()
		darkness.set_color(Color("868686"))

func _on_library_threshold_entered(body):
	# Only proceed if the colliding body is the player
	if body == player:
		await wait_until_grounded()  # Ensure player is stable before continuing
		
		# Save current camera position for smooth transition
		var current_position = camera.position
		
		# Zoom in the camera slightly but maintain the camera position
		camera.zoom = Vector2(0.6, 0.6)  # Increase zoom (adjust value as needed)
		
		# Set the camera to library mode first to ensure smooth transition
		camera.set_library_mode(true)
		
		# Adjust camera bounds for the library area
		update_library_camera_bounds()
		
		# Change lighting if needed
		darkness.set_color(Color("767676"))
	elif body.name.contains("TileMap"):
		pass

func wait_until_grounded():
	var timeout = 5.0  # 5 second timeout
	var start_time = Time.get_ticks_msec()
	
	while not player.is_on_floor():  
		if Time.get_ticks_msec() - start_time > timeout * 1000:
			break
		await get_tree().process_frame  

func update_camera_bounds():
	if not dining_threshold:
		return

	# Lock camera's left side at dining_threshold's position
	camera.limit_left = dining_threshold.global_position.x  
	# Effectively remove limits in all other directions
	camera.limit_right = 999999  # Allow movement to the right indefinitely
	camera.limit_top = -999999   # No limit upwards
	camera.limit_bottom = 999999  # No limit downwards

	# Optional: Adjust camera offset if necessary
	camera.offset = Vector2(0, -100)
	
func move_player_slowly():
	if player:
		player.set_can_move(false)
		moving_player = true

func drop_wall():
	if wall_fall:
		wall_fall.play("wall")
		await wall_fall.animation_finished  # Wait until the animation finishes
		if player:
			player.set_can_move(true)  # Allow player movement after animation ends

func update_library_camera_bounds():
	if not library_threshold:
		return
	
	# Ensure camera is properly set up to follow the player
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	# Turn off drag to avoid interference with custom following logic
	camera.drag_horizontal_enabled = false
	
	# Get the player's current position
	var player_pos = player.global_position
	
	# Set camera bounds to fit the library level
	# Now using player's position for left boundary, not the threshold position
	var left_boundary = player_pos.x - 1000  # Generous padding to the left
	var right_boundary = left_boundary + 100000  # Approximate width of library area
	
	# Ensure we don't go too far left
	left_boundary = max(left_boundary, 12000)  # Don't go below X=12000
	
	camera.limit_left = left_boundary
	camera.limit_right = right_boundary
	
	# Set vertical bounds to much wider values for the library to allow exploration
	camera.limit_top = -1500  # Allow camera to go up to Y = -1000
	camera.limit_bottom = 2000
	
	# Optional: Adjust camera offset if needed
	camera.offset = Vector2(0, 0)

# Helper function to find an Area2D in children recursively
func find_area2d_in_children(node):
	# Check if this node is an Area2D
	if node is Area2D:
		return node
		
	# Check all children recursively
	for child in node.get_children():
		var result = find_area2d_in_children(child)
		if result:
			return result
			
	return null

# Configure the library threshold to only detect the player
func configure_library_threshold(threshold):
	if threshold is Area2D:
		# First, try to use collision layers if they exist in the project
		if ClassDB.class_exists("PhysicsLayer"):
			threshold.collision_layer = 0  # Don't be detected by anything
			threshold.collision_mask = 1   # Only detect player (assuming player is on layer 1)
		
		# For extra certainty, check if we can use the monitoring property
		if threshold.has_method("set_monitorable"):
			threshold.set_monitorable(false)  # Don't let others detect this area
		
		if threshold.has_method("set_monitoring"):
			threshold.set_monitoring(true)   # Allow this area to detect others
