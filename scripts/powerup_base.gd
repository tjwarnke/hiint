extends Area2D

@export var power_type: String = "Base"  # The type of powerup
@export var power_value: int = 1  # The value/amount of the powerup

signal collected(power_type, power_value)

func _ready():
	add_to_group("powerup")
	
	# Connect to body_entered signal
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if collected:
		return
		
	if body.is_in_group("player"):
		# Apply powerup to player
		if body.has_method("_on_powerup_collected"):
			body._on_powerup_collected(power_type, power_value)
			collected = true
			queue_free() 
