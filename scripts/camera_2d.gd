extends Camera2D

@export var player: CharacterBody2D  # Assign the player dynamically
@export var deadzone: float = 100.0  # Free movement area before camera moves
@export var follow_speed: float = 3.0  # Speed of camera movement
@export var fixed_y: float = 600.0  # The locked Y position (100 pixels higher)
@export var zoom_level: Vector2 = Vector2(0.5, 0.5)  # Camera zoom level

func _ready():
	# Set initial zoom
	zoom = zoom_level

func _process(delta):
	if player:
		var target_x = player.position.x  # Target is player's position
		var distance_x = abs(target_x - position.x)

		if distance_x > deadzone:
			# Calculate the direction to move
			var direction = 1 if target_x > position.x else -1
			# Move towards target with smooth interpolation
			position.x = lerp(position.x, target_x, follow_speed * delta)
		else:
			# If within deadzone, stay put
			position.x = position.x

		# Keep Y position fixed
		position.y = fixed_y
