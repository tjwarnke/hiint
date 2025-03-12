extends Area2D

var player_in_area = null  # Stores reference to player when in range
var can_be_picked_up = true
signal picked()

func _on_body_entered(body):
		player_in_area = body  # Store player reference

func _on_body_exited(_body):
		player_in_area = null  # Remove reference when player leaves

func _process(delta):
	
	if player_in_area and Input.is_action_just_pressed("pick_up") and can_be_picked_up:
		picked.emit()
		player_in_area.pick_up_torch(self)  # Call player’s function
		can_be_picked_up = false
