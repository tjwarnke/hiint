extends Camera2D

@export var player: CharacterBody2D  # Assign the player dynamically
@export var deadzone: float = 100.0  # Free movement area before camera moves
@export var follow_speed: float = 3.0  # Speed of camera movement
@export var fixed_y: float = 550.0  # The locked Y position

func _process(delta):
	if player:
		var distance_x = abs(player.position.x - position.x)

		if distance_x > deadzone:
			# Smoothly follow player on X-axis, keep Y fixed
			position.x = lerp(position.x, player.position.x, follow_speed * delta)

		# Force Y position to always stay at fixed_y
		position.y = fixed_y
