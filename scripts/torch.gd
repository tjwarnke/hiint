extends Area2D

signal torch_picked

var player_in_area = null  
var can_be_picked_up = true
@onready var text_box = get_tree().current_scene.find_child("TextBoxMiddleTop", true, false)


func _ready(): 
	add_to_group("item")

func _on_body_entered(body):
	player_in_area = body  
	if can_be_picked_up and text_box:
		text_box.visible = true
		text_box.text = "Press 'e' to take Torch"

func _on_body_exited(_body):
	player_in_area = null  
	if text_box:
		text_box.visible = false
	
	
func _process(_delta):
	if player_in_area and Input.is_action_just_pressed("pick_up") and player_in_area.has_method("pick_up_item"):
		if player_in_area.held_item != null:
			return
		if can_be_picked_up:
			if text_box:
				text_box.visible = false
			torch_picked.emit()
			player_in_area.pick_up_item(self)
			can_be_picked_up = false
