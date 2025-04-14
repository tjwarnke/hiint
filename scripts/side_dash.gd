extends Area2D

# Set dash power as 1 to allow only one dash
@export var dash_power = 1

var collected = false  # Flag to prevent multiple collections

func _ready():
	add_to_group("powerup")
	print("[DASH POWERUP] Initialized at position: ", global_position)

func _on_body_entered(body):
	# Don't handle collection if already collected
	if collected:
		return
		
	if body.is_in_group("player") and body.has_method("_on_powerup_collected") and not collected:
		collected = true
		print("[DASH POWERUP] Collection triggered by player at position:", global_position)
		
		# Call the player's powerup collection method
		body._on_powerup_collected("Dash", dash_power)
		
		# Remove immediately
		queue_free()
