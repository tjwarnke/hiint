extends Camera2D

@export var player: CharacterBody2D  # Assign the player dynamically
@export var deadzone: float = 100.0  # Free movement area before camera moves
@export var follow_speed: float = 3.0  # Speed of camera movement
@export var fixed_y: float = 550.0  # The locked Y position

func _process(delta):
	if player:
		var target_x = player.position.x - 5000  # Apply 2000px offset
		var distance_x = abs(target_x - position.x)

		if distance_x > deadzone:
			position.x = lerp(position.x, target_x, follow_speed * delta)
		else:
			position.x = target_x  

		# Keep Y position fixed
		position.y = fixed_y
