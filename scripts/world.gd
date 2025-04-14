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
@onready var MainMusic = get_node("/root/MainMusic")

# Dining room nodes (will be set after scene is loaded)
var dining_wall = null
var dining_threshold = null
var wall_fall = null
var library_threshold = null
var billiards_dungeon_threshold = null
var level_transition_active = false

var moving_player = false
var move_distance = 500
var move_speed = 100.0
var camera_smooth_speed = 0.0001  # Adjust this value for smoother/slower movement

# Audio for the dungeon area
var dungeon_music_player = null

func _ready():
	# Set the default darker color for tutorial area
	if darkness:
		darkness.color = Color("555555")  # Darker gray for tutorial area
	
	# Initialize the powerup effect system
	setup_powerup_effect_system()
	
	# Spawn the player properly
	spawn_player()
	
	initialize_game_state()
	
	# Initialize camera immediately after player spawning
	if player and camera:
		set_camera_target()
	else:
		call_deferred("set_camera_target")
	
	# Connect the dungeon threshold if it exists
	var dungeon_entered = get_node_or_null("Billiards/dungeon_entered")
	if dungeon_entered and dungeon_entered is Area2D:
		dungeon_entered.body_entered.connect(_on_dungeon_entered)
		print("[WORLD] Connected dungeon entrance trigger")
	else:
		push_warning("Dungeon entrance trigger not found")
	
	# Setup the library lever
	setup_library_lever()
	
	# Add pause menu
	pause_menu = PauseMenuScene.instantiate()
	# Add to the root viewport to ensure it's above everything
	get_tree().root.add_child(pause_menu)
	
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
		
	# Look for billiards to dungeon threshold
	billiards_dungeon_threshold = get_node_or_null("BilliardsRoom/dungeon_threshold")
	if billiards_dungeon_threshold:
		billiards_dungeon_threshold.body_entered.connect(_on_dungeon_threshold_entered)
	else:
		push_warning("Dungeon threshold not found - will need to be added to the scene")
		
	wall_fall = $DiningRoom/WallFall
	if not wall_fall:
		push_error("Wall fall animation not found!")

func _process(delta):
	# Original code
	if Engine.get_process_frames() % 10 == 0:
		handle_input()
	
	handle_player_movement(delta)
	
	# Only check camera position occasionally to reduce CPU load
	if player and camera and Engine.get_process_frames() % 30 == 0:
		# Every 30 frames, verify camera is following player correctly
		var distance = abs(camera.position.x - player.position.x)
		if distance > 300 and not moving_player:
			camera.position.x = player.position.x
			if camera.in_library_area:
				camera.position.y = player.position.y
			else:
				camera.position.y = camera.fixed_y
	
	# Check for lever interaction - kept simple
	if Input.is_action_just_pressed("ui_accept"):  # Changed from "interact" to "ui_accept"
		var lever = get_node_or_null("Library/Lever")
		
		if lever and player:
			# Check if player is near the lever (150 pixel radius)
			var distance_to_lever = player.global_position.distance_to(lever.global_position)
			if distance_to_lever < 150:
				var hidden_platform = get_node_or_null("Library/HiddenPlatform")
				if hidden_platform:
					activate_lever(hidden_platform)

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
	
	# Set music to extremely quiet initially (-200db)
	var main_music = get_node_or_null("/root/MainMusic")
	if main_music and main_music.has_method("set_volume_db"):
		main_music.set_volume_db(-200.0)
		print("[WORLD] Set initial music to silent (-200db)")
	
	# Add ambient noise (but make sure its volume is moderate)
	add_child(ambient_noise)
	ambient_noise.set_volume_level(-10.0)  # Set a reasonable volume
	
	# Start a timer to fade out music after player has had time to orient
	var music_fade_timer = Timer.new()
	music_fade_timer.wait_time = 3.0  # Wait 3 seconds before fading music
	music_fade_timer.one_shot = true
	music_fade_timer.autostart = true
	music_fade_timer.timeout.connect(fade_music_after_start)
	add_child(music_fade_timer)

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
	print("[WORLD] Spawning player...")
	player = PlayerScene.instantiate()
	if not player:
		push_error("[WORLD] Failed to instantiate player scene")
		return

	add_child(player)
	print("[WORLD] Player added to scene")

	# Ensure spawn exists before setting position
	if not spawn:
		push_error("[WORLD] Spawn node is missing! Player will be placed at origin")
		player.position = Vector2(0, 0)
	else:
		print("[WORLD] Setting player position to spawn: ", spawn.global_position)
		player.global_position = spawn.global_position
	
	# Set camera settings
	if camera:
		print("[WORLD] Configuring camera settings")
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		camera.drag_horizontal_enabled = true
		camera.drag_left_margin = 0.1
		camera.drag_top_margin = 0.1
		camera.drag_right_margin = 0.1
		camera.drag_bottom_margin = 0.1
	else:
		push_error("[WORLD] Camera not found when spawning player")

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
	if body == player and not level_transition_active:
		level_transition_active = true
		await wait_until_grounded()
		update_camera_bounds()
		
		# Play a transition animation
		play_level_transition("dining")
		
		# After animation, continue with existing logic
		move_player_slowly()
		
		# Ensure ambient noise plays the dining sound
		if ambient_noise and ambient_noise.has_method("on_dining"):
			ambient_noise.on_dining()
			print("[WORLD] Playing dining room ambient sounds")
		
		# Make the dining room area lighter
		if darkness:
			darkness.color = Color("a8a8a8")  # Use a lighter gray for dining room
			
		# Start playing the game_level.mp3 music
		var main_music = get_node_or_null("/root/MainMusic")
		if main_music:
			if main_music.has_method("play_level_music"):
				main_music.play_level_music("res://assets/audio/game_level.mp3")
				print("[WORLD] Playing game_level.mp3 in dining room")
			elif main_music.has_method("play"):
				var stream = load("res://assets/audio/game_level.mp3")
				if stream:
					main_music.stream = stream
					main_music.play()
					main_music.volume_db = -10.0  # Set to normal volume
					print("[WORLD] Playing game_level.mp3 in dining room (direct method)")
				else:
					push_error("Failed to load game_level.mp3")

func _on_library_threshold_entered(body):
	# Only proceed if the colliding body is the player
	if body == player and not level_transition_active:
		level_transition_active = true
		await wait_until_grounded()  # Ensure player is stable before continuing
		
		print("[LIBRARY] Player entered library area")
		
		# Verify player's jump ability
		if player and "max_jumps" in player:
			print("[LIBRARY] Player jump status - max jumps: ", player.max_jumps, ", jumps left: ", player.jumps_left)
			
			# If player doesn't have double jump yet, we can verify they'll be able to get it
			if player.max_jumps < 2:
				print("[LIBRARY] Player will be able to obtain double jump in library")
			else:
				print("[LIBRARY] Player already has double jump capability")
		
		# Print information about the library area powerups
		var powerups = get_tree().get_nodes_in_group("powerup")
		var library_powerups = []
		for powerup in powerups:
			# Check if the powerup is in the Library area (assuming it has "Library" in its path)
			if str(powerup.get_path()).find("Library") >= 0:
				library_powerups.append(powerup)
				print("[LIBRARY] Found powerup in library: ", powerup.name, " at position ", powerup.global_position)
				
				# If it's a jump powerup, verify its settings
				if powerup.name.contains("Jump") or ("jump_power" in powerup and powerup.jump_power > 0):
					var jump_power_value = 1  # Default value
					if "jump_power" in powerup:
						jump_power_value = powerup.jump_power
						
					var is_collected = false  # Default value
					if "collected" in powerup:
						is_collected = powerup.collected
						
					print("[LIBRARY] This is a jump powerup with jump_power: ", 
						  jump_power_value, ", collected: ", is_collected)
		
		print("[LIBRARY] Found ", library_powerups.size(), " powerups in the library area")
		
		# Play a transition animation
		play_level_transition("library")
		
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
		
		# Reset transition flag
		level_transition_active = false
		
		print("[LIBRARY] Library setup complete, player movement restored")
	elif body.name.contains("TileMap"):
		pass

func _on_dungeon_threshold_entered(body):
	if body == player and not level_transition_active:
		level_transition_active = true
		await wait_until_grounded()  # Ensure player is stable before continuing
		
		# Play a transition animation
		play_level_transition("dungeon")
		
		# Additional dungeon-specific camera and lighting adjustments could go here
		
		# Reset transition flag
		level_transition_active = false

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
		# Set a reasonable limit to prevent infinite movement
		move_distance = min(move_distance, 1000)  # Prevent excessive movement distance

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

# Play a transition animation based on the level being entered
func play_level_transition(level_name: String):
	# Disable player movement during transition
	if player:
		player.set_can_move(false)
	
	match level_name:
		"dining":
			if wall_fall:
				wall_fall.play("wall")
				await wall_fall.animation_finished
		"library":
			# Create a simple door closing animation with ColorRect
			var transition_rect = ColorRect.new()
			transition_rect.color = Color(0, 0, 0, 0)
			transition_rect.size = DisplayServer.window_get_size()
			transition_rect.position = Vector2.ZERO
			add_child(transition_rect)
			
			# Animate the transition
			var tween = create_tween()
			tween.tween_property(transition_rect, "color", Color(0, 0, 0, 1), 0.5)
			await tween.finished
			await get_tree().create_timer(0.5).timeout
			
			var tween2 = create_tween()
			tween2.tween_property(transition_rect, "color", Color(0, 0, 0, 0), 0.5)
			await tween2.finished
			
			# Remove the transition rect
			transition_rect.queue_free()
		"billiards":
			# Create a simple door closing animation with ColorRect
			var transition_rect = ColorRect.new()
			transition_rect.color = Color(0, 0, 0, 0)
			transition_rect.size = DisplayServer.window_get_size()
			transition_rect.position = Vector2.ZERO
			add_child(transition_rect)
			
			# Animate the transition
			var tween = create_tween()
			tween.tween_property(transition_rect, "color", Color(0, 0, 0, 1), 0.5)
			await tween.finished
			await get_tree().create_timer(0.5).timeout
			
			var tween2 = create_tween()
			tween2.tween_property(transition_rect, "color", Color(0, 0, 0, 0), 0.5)
			await tween2.finished
			
			# Remove the transition rect
			transition_rect.queue_free()
		"dungeon":
			# Floor fold-out animation for dungeon
			var dungeon_transition = create_dungeon_transition()
			add_child(dungeon_transition)
			
			# Play the animation
			dungeon_transition.play_transition()
			await dungeon_transition.transition_finished
			
			# Remove the transition
			dungeon_transition.queue_free()
		_:
			# Default transition
			await get_tree().create_timer(0.5).timeout
	
	# Re-enable player movement after transition
	if player:
		player.set_can_move(true)
	
	# Reset transition flag
	level_transition_active = false

# Create a floor fold-out animation for dungeon
func create_dungeon_transition():
	var dungeon_transition = Node2D.new()
	dungeon_transition.name = "DungeonTransition"
	
	# Create floor panels
	var panel_count = 10
	var panel_width = 192
	var panels = []
	
	for i in range(panel_count):
		var panel = ColorRect.new()
		panel.color = Color(0.3, 0.25, 0.2)
		panel.size = Vector2(panel_width, 20)
		panel.position = Vector2(i * panel_width, -20)
		panel.rotation = -PI/2  # Start rotated up
		dungeon_transition.add_child(panel)
		panels.append(panel)
	
	# Add transition finished signal
	dungeon_transition.set_script(create_transition_script())
	
	# Add play_transition method to animate the floor panels
	dungeon_transition.panels = panels
	
	return dungeon_transition

# Create a script for the dungeon transition
func create_transition_script():
	var script = GDScript.new()
	script.source_code = """
extends Node2D

signal transition_finished

var panels = []

func play_transition():
	# Animate each panel sequentially
	for i in range(panels.size()):
		var panel = panels[i]
		var tween = create_tween()
		tween.tween_property(panel, "rotation", 0, 0.2)
		await get_tree().create_timer(0.1).timeout
	
	# Emit signal when all panels are done
	await get_tree().create_timer(0.5).timeout
	transition_finished.emit()
"""
	script.reload()
	return script

# New function to fade music after the level has started
func fade_music_after_start():
	var main_music = get_node_or_null("/root/MainMusic")
	if main_music and main_music.has_method("fade_out_music_only"):
		main_music.fade_out_music_only(5.0)  # Fade out music after player is in the level

# Handler for dungeon entrance - simplified 
func _on_dungeon_entered(body):
	if body.is_in_group("player"):
		print("[WORLD] Player entered dungeon area")
		
		# Zoom in camera for dungeon effect
		var original_zoom = camera.zoom
		var tween = create_tween()
		tween.tween_property(camera, "zoom", Vector2(0.3, 0.3), 0.5)
		
		# Wait until player touches ground to zoom back out
		create_timer_to_check_grounded(original_zoom)
		
		# Fade out current music
		var main_music = get_node_or_null("/root/MainMusic")
		if main_music and main_music.has_method("fade_out_music_only"):
			main_music.fade_out_music_only(2.0)
		
		# Start dungeon music
		setup_dungeon_music()

# Simple timer to check if player is grounded
func create_timer_to_check_grounded(original_zoom):
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	add_child(timer)
	
	timer.timeout.connect(func():
		if player and player.is_on_floor():
			var tween = create_tween()
			tween.tween_property(camera, "zoom", original_zoom, 1.0)
			timer.queue_free()
	)

# Setup dungeon music player
func setup_dungeon_music():
	if not dungeon_music_player:
		dungeon_music_player = AudioStreamPlayer.new()
		dungeon_music_player.stream = preload("res://assets/audio/dungeon.mp3")
		dungeon_music_player.volume_db = -10.0
		dungeon_music_player.bus = "Music"
		add_child(dungeon_music_player)
		dungeon_music_player.play()

# Set up the powerup effect system
func setup_powerup_effect_system():
	print("[WORLD] Setting up powerup effect system...")
	
	# Connect to all powerups to handle visual effects
	call_deferred("connect_to_powerups_for_effects")
	
	# Also set up a timer to regularly check for new powerups
	var powerup_check_timer = Timer.new()
	powerup_check_timer.wait_time = 2.0  # Check every 2 seconds
	powerup_check_timer.autostart = true
	powerup_check_timer.timeout.connect(connect_to_powerups_for_effects)
	add_child(powerup_check_timer)
	print("[WORLD] Powerup effect system initialized with periodic check timer")

# Connect to all powerups to add visual effects when collected
func connect_to_powerups_for_effects():
	var powerups = get_tree().get_nodes_in_group("powerup")
	print("[WORLD] Found ", powerups.size(), " powerups to connect")
	
	for powerup in powerups:
		print("[WORLD] Checking powerup: ", powerup.name, " at position ", powerup.global_position)
		
		# Check if this powerup is already connected
		var is_connected = false
		if powerup.get_signal_connection_list("body_entered").size() > 0:
			for connection in powerup.get_signal_connection_list("body_entered"):
				if connection.callable.get_method() == "handle_powerup_collection_effect":
					is_connected = true
					break
		
		if not is_connected:
			print("[WORLD] Connecting to powerup: ", powerup.name)
			powerup.connect("body_entered", Callable(self, "handle_powerup_collection_effect").bind(powerup))
		else:
			print("[WORLD] Powerup already connected: ", powerup.name)

# Generate a visual effect when a powerup is collected
func handle_powerup_collection_effect(body, powerup):
	print("[WORLD] Powerup collection effect triggered by: ", body.name if body else "unknown")
	
	# Only proceed if it's the player collecting a powerup that hasn't been collected
	if body.is_in_group("player") and powerup.is_in_group("powerup"):
		print("[WORLD] Player collecting powerup: ", powerup.name)
		
		# Check if already collected
		var already_collected = false
		if "collected" in powerup and powerup.collected:
			already_collected = true
			print("[WORLD] Powerup already collected, skipping effect")
		
		if not already_collected:
			# Determine the effect type based on powerup
			var effect_color = Color(1, 1, 1)  # Default white
			if powerup.name.contains("Jump") or ("jump_power" in powerup):
				effect_color = Color(0.2, 0.8, 1.0, 1.0)  # Blue for jump
				print("[WORLD] Creating blue jump powerup effect")
			elif powerup.name.contains("Dash") or ("dash_power" in powerup):
				effect_color = Color(1.0, 0.4, 0.0, 1.0)  # Orange for dash
				print("[WORLD] Creating orange dash powerup effect")
			else:
				print("[WORLD] Creating default white powerup effect")
			
			# Create the effect at the powerup's position
			create_powerup_collection_effect(powerup.global_position, effect_color)
			
			# Mark as collected to prevent duplicate effects
			if "collected" in powerup:
				powerup.collected = true
				print("[WORLD] Marked powerup as collected: ", powerup.name)
	else:
		print("[WORLD] Powerup collection ignored - not player or not a powerup")

# Create a visual effect for powerup collection
func create_powerup_collection_effect(position, color):
	print("[WORLD] Creating powerup collection effect at position: ", position)
	
	# Create a new particle system for the effect
	var effect = CPUParticles2D.new()
	effect.emitting = false
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.lifetime = 0.7
	effect.amount = 60
	effect.spread = 180
	effect.gravity = Vector2(0, 60)
	effect.initial_velocity_min = 100
	effect.initial_velocity_max = 250
	effect.scale_amount_min = 4.0
	effect.scale_amount_max = 6.0
	effect.color = color
	
	# Add the effect to the scene
	add_child(effect)
	effect.position = position
	effect.emitting = true
	print("[WORLD] Particle effect started emitting")
	
	# Create a timer to remove the effect after it's done
	var timer = Timer.new()
	timer.wait_time = effect.lifetime + 0.1  # Add a small buffer
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	
	# Connect the timer to remove the effect
	timer.timeout.connect(func():
		print("[WORLD] Cleaning up powerup effect")
		effect.queue_free()
		timer.queue_free()
	)

# Setup the library lever and hidden platform
func setup_library_lever():
	# Find the lever in the library
	var lever = get_node_or_null("Library/Lever")
	if not lever:
		# Try alternative paths
		var alternative_paths = [
			"Library/lever", 
			"Library/InteractiveObjects/Lever"
		]
		
		for path in alternative_paths:
			lever = get_node_or_null(path)
			if lever:
				break
	
	# Find the hidden platform
	var hidden_platform = get_node_or_null("Library/HiddenPlatform")
	if not hidden_platform:
		# Try alternative paths
		var alternative_paths = [
			"Library/hidden_platform", 
			"Library/Platforms/HiddenPlatform"
		]
		
		for path in alternative_paths:
			hidden_platform = get_node_or_null(path)
			if hidden_platform:
				break
	
	if lever and hidden_platform:
		print("[WORLD] Found library lever and hidden platform")
		# Make the platform initially invisible/inactive
		if hidden_platform.has_method("set_visible"):
			hidden_platform.set_visible(false)
		elif "visible" in hidden_platform:
			hidden_platform.visible = false
		
		# Connect the lever to an interaction function
		if lever is Area2D:
			lever.connect("body_entered", Callable(self, "_on_lever_body_entered").bind(hidden_platform))
			lever.set_meta("interactable", true)
		else:
			print("[WORLD] Warning: Lever is not an Area2D")
	else:
		if not lever:
			print("[WORLD] Warning: Could not find library lever")
		if not hidden_platform:
			print("[WORLD] Warning: Could not find hidden platform")

# Handle lever body entered
func _on_lever_body_entered(body, hidden_platform):
	if body.is_in_group("player") and hidden_platform:
		print("[WORLD] Player entered lever area")
		# Show a hint to the player
		var text_box = get_node_or_null("UI/TextBoxMiddleTop")
		if text_box:
			text_box.visible = true
			text_box.text = "Press 'E' to activate the lever"
			
			# Create a timer to hide the text after a delay
			var timer = get_tree().create_timer(3.0)
			await timer.timeout
			if text_box:
				text_box.visible = false

# Simple lever activation
func activate_lever(hidden_platform):
	print("[WORLD] Activating library lever")
	
	# Show message
	var text_box = get_node_or_null("UI/TextBoxMiddleTop")
	if text_box:
		text_box.visible = true
		text_box.text = "A hidden platform has appeared!"
		
		# Hide after a delay
		var timer = get_tree().create_timer(3.0)
		await timer.timeout
		if text_box:
			text_box.visible = false
	
	# Make the platform visible and active
	if hidden_platform:
		if "visible" in hidden_platform:
			hidden_platform.visible = true
		
		# Enable collision if property exists
		if "collision_layer" in hidden_platform:
			hidden_platform.collision_layer = 1
		
		print("[WORLD] Hidden platform activated")
