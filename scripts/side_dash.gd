extends Area2D
# Set dash power as 1 to allow only one dash
@export var dash_power = 1

var collected = false  # Flag to prevent multiple collections

func _ready():
	add_to_group("powerup")
	
	# Connect to body_entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if collected:
		return
		
	if body.is_in_group("player"):
		# Apply dash power to player first
		if body.has_method("_on_powerup_collected"):
			body._on_powerup_collected("Dash", dash_power)
			collected = true
			
			# Create a new powerup effect at the current position
			var effect_scene = load("res://scenes/powerup_effect.tscn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				if effect:
					effect.position = global_position
					get_tree().root.add_child(effect)
					effect.set_color(Color(1, 0.5, 0))  # Orange color for dash
			
			# Queue free after everything else is done
			queue_free()
