extends "res://scripts/powerup_base.gd"

var text_box = null

func _ready():
	# Set the power type and value
	power_type = "Dash"
	power_value = 1
	
	# Call parent _ready to set up signal and group
	super._ready()
	text_box = get_node_or_null("../../UI/TextBoxMiddleTop")

func _on_body_entered_dash(_body):
	collected.emit(power_type, power_value)  # Emit signal to notify collection
	queue_free()  # Remove the power-up
	text_box.visible = true
	text_box.text = "You have collected Double Jump!"
	await get_tree().create_timer(1.5).timeout
	text_box.visible = false
