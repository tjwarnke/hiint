extends Area2D

signal torch_picked

var player_in_area = null  
var can_be_picked_up = true


func _ready(): 
	add_to_group("item")

func _on_body_entered(body):
	player_in_area = body  

func _on_body_exited(_body):
	player_in_area = null  

func _process(_delta):
	if player_in_area and Input.is_action_just_pressed("pick_up") and player_in_area.has_method("pick_up_item"):
		if player_in_area.held_item != null:
			return
		if can_be_picked_up:
			torch_picked.emit()
			player_in_area.pick_up_item(self)
			can_be_picked_up = false
