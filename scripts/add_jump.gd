extends Area2D

@export var power_type: String = "Jump" # Can be customized for different power-ups

signal collected(power_type)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered_jump"))
	

func _on_body_entered_jump(_body):
	collected.emit(power_type)  # Emit signal to notify collection
	queue_free()  # Remove the power-up
