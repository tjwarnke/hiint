extends "res://scripts/powerup_base.gd"

func _ready():
	# Set the power type and value
	power_type = "Jump"
	power_value = 1
	
	# Call parent _ready to set up signal and group
	super._ready()

func _on_body_entered_jump(_body):
	collected.emit(power_type, power_value)  # Emit signal to notify collection
	queue_free()  # Remove the power-up
