extends Area2D

# Set jump power as 1 to make it a double jump (1+1=2 total jumps)
@export var jump_power = 1

var collected = false  # Flag to prevent multiple collections

func _ready():
	add_to_group("powerup")
	print("[JUMP POWERUP] Initialized at position: ", global_position)
	
	# Connect to body_entered signal
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
		print("[JUMP POWERUP] Connected to body_entered signal")

func _on_body_entered(body):
	print("[JUMP POWERUP] Body entered: ", body.name if body else "unknown")
	
	# Don't handle collection if already collected
	if collected:
		print("[JUMP POWERUP] Already collected, ignoring")
		return
		
	if body.is_in_group("player") and body.has_method("_on_powerup_collected") and not collected:
		print("[JUMP POWERUP] Player collecting jump powerup")
		
		# Call the player's powerup collection method
		body._on_powerup_collected("Jump", jump_power)
		print("[JUMP POWERUP] Applied jump power to player")
		
		# Mark as collected AFTER the effect system has had a chance to create the particle effect
		collected = true
		
		# Remove immediately
		queue_free()
		print("[JUMP POWERUP] Removed from scene")
	else:
		print("[JUMP POWERUP] Ignored - not player or missing _on_powerup_collected method")
