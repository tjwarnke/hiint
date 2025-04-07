extends Area2D

@export var power_type: String = "Base"  # The type of powerup
@export var power_value: int = 1  # The value/amount of the powerup

signal collected(power_type, power_value)

func _ready():
	print("Powerup ready: ", power_type, " with value: ", power_value)  # Debug print
	# Connect to body_entered signal
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Add to powerup group for easy finding
	add_to_group("powerup")
	print("Added to powerup group")  # Debug print

func _on_body_entered(body):
	print("Body entered powerup: ", body)  # Debug print
	if body.is_in_group("player"):
		print("Player collected powerup!")  # Debug print
		# Emit signal with power type and value
		collected.emit(power_type, power_value)
		# Remove the powerup
		queue_free() 
