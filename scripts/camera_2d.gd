extends Camera2D

@export var player: CharacterBody2D  # Assign the player dynamically
@export var deadzone: float = 100.0  # Free movement area before camera moves
@export var follow_speed: float = 2.0  # Speed of camera movement (reduced from 3.0)
@export var fixed_y: float = 600.0  # The locked Y position (100 pixels higher)
@export var zoom_level: Vector2 = Vector2(0.5, 0.5)  # Camera zoom level

# Track if we're in a special area with different camera behavior
var in_library_area = false
var original_drag_enabled = true
var last_player_position = Vector2.ZERO
var smooth_position = Vector2.ZERO

var in_dungeon_area = false
var dungeon_min_y = 100

func _ready():
	# Set initial zoom
	zoom = zoom_level
	original_drag_enabled = drag_horizontal_enabled
	if player:
		last_player_position = player.position
		smooth_position = Vector2(player.position.x, fixed_y)
		position = smooth_position

func _process(delta):
	if player:
		# Calculate target position based on mode
		var target_position = Vector2.ZERO
		if in_library_area:
			target_position = player.position  # Follow both X and Y in library
		elif in_dungeon_area:
			target_position = player.position
			target_position.y = max(dungeon_min_y, player.position.y)
		else:
			target_position = Vector2(player.position.x, fixed_y)  # Fixed Y elsewhere
		
		# Check if player has moved significantly
		var player_moved = player.position.distance_to(last_player_position) > 5
		
		# Force update only if very far from player
		if player.position.distance_to(position) > 500:
			smooth_position = target_position
			position = smooth_position
		else:
			# Smooth movement always, but at different speeds based on distance
			var distance = player.position.distance_to(position)
			var current_speed = follow_speed
			
			# Adjust speed based on distance - faster when further away
			if distance > 300:
				current_speed = 5.0
			elif distance > 200:
				current_speed = 3.5
			elif distance > 100:
				current_speed = 2.5
			
			# Use smooth_position for interpolation to avoid judder
			smooth_position = smooth_position.lerp(target_position, current_speed * delta)
			position = smooth_position
		
		# Save last player position to detect movement
		last_player_position = player.position

# Called by World script to set library area mode
func set_library_mode(enabled: bool):
	in_library_area = enabled
	if enabled:
		# Store original state to restore later if needed
		original_drag_enabled = drag_horizontal_enabled
		drag_horizontal_enabled = false
		position_smoothing_enabled = true
		position_smoothing_speed = 3.0  # Faster smoothing for library transitions
		
		# Reset smooth position to prevent jumps
		if player:
			smooth_position = Vector2(player.position.x, player.position.y)
	else:
		# Restore original settings
		drag_horizontal_enabled = original_drag_enabled
		smooth_position.y = fixed_y
		position.y = fixed_y
		
func set_dungeon_mode(enabled: bool):
	in_dungeon_area = enabled
	if enabled:
		# Zoom in closer for dungeon feel
		var tween = create_tween()
		tween.tween_property(self, "zoom", Vector2(0.3, 0.3), 0.5)
		
		# Optional: If you want to follow Y axis too, like in library
		in_library_area = true  # Reuse existing logic
		
		# Optional: Smooth transitions even more inside dungeon
		position_smoothing_enabled = true
		position_smoothing_speed = 4.0
	else:
		# Restore normal zoom and behavior
		var tween = create_tween()
		tween.tween_property(self, "zoom", zoom_level, 0.5)
		
		in_library_area = false
		position_smoothing_enabled = false
