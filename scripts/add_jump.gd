extends Area2D

# Set jump power as 1 to make it a double jump (1+1=2 total jumps)
@export var jump_power = 1

var collected = false  # Flag to prevent multiple collections

var PowerupEffect = preload("res://scenes/powerup_effect.tscn")

func _ready():
	add_to_group("powerup")
	
	# Connect to body_entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if collected:
		return
		
	if body.is_in_group("player"):
		# Create and play the powerup effect
		var effect = PowerupEffect.instantiate()
		if effect:
			effect.position = global_position
			get_tree().root.add_child(effect)
			effect.set_color(Color(0, 0.5, 1))  # Blue color for jump
		
		# Apply jump power to player
		if body.has_method("_on_powerup_collected"):
			body._on_powerup_collected("Jump", jump_power)
			collected = true
			queue_free()
