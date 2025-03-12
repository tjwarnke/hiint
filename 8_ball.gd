extends Area2D

var player_in_area = null  
var can_be_picked_up = true
signal picked()

func _on_body_entered(body):
	player_in_area = body  

func _on_body_exited(_body):
	player_in_area = null  

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("pick_up") and can_be_picked_up:
		player_in_area.pick_up_item(self)
		can_be_picked_up = false

func _ready():
	add_to_group("item")
