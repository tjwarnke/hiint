extends Area2D

# Set dash power as 1 to allow only one dash
@export var dash_power = 1

var collected = false  # Flag to prevent multiple collections

func _ready():
	add_to_group("powerup")
	print("[DASH POWERUP] Initialized at position: ", global_position)
	
	# Connect to body_entered signal
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
		print("[DASH POWERUP] Connected to body_entered signal")

func _on_body_entered(body):
	print("[DASH POWERUP] Body entered: ", body.name if body else "unknown")
	
	# Don't handle collection if already collected
	if collected:
		print("[DASH POWERUP] Already collected, ignoring")
		return
		
	if body.is_in_group("player") and body.has_method("_on_powerup_collected") and not collected:
		print("[DASH POWERUP] Player collecting dash powerup")
		
		# Call the player's powerup collection method
		body._on_powerup_collected("Dash", dash_power)
		print("[DASH POWERUP] Applied dash power to player")
		
		# Mark as collected AFTER the effect system has had a chance to create the particle effect
		collected = true
		
		# Remove immediately
		queue_free()
		print("[DASH POWERUP] Removed from scene")
	else:
		print("[DASH POWERUP] Ignored - not player or missing _on_powerup_collected method")
