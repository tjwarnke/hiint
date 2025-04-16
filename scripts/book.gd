extends RigidBody2D

var player_in_area = null  
var can_be_picked_up = true
var original_scale = Vector2(1, 1)  # Store original scale for player holding

@onready var text_box = get_node_or_null("/root/World/UI/TextBoxMiddleTop")
@onready var area = get_node("Area2D")

func _ready(): 
	add_to_group("item")
	# Store the original scale for later use
	original_scale = scale
	
	# Each book instance will individually control their pickup state

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = body 
		if can_be_picked_up and text_box:
			text_box.visible = true
			text_box.text = "Press 'e' to take Book" 

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = null
		if text_box:
			text_box.visible = false

func _process(_delta):
	if player_in_area and Input.is_action_just_pressed("pick_up") and player_in_area.has_method("pick_up_item"):
		if can_be_picked_up:
			if text_box:
				text_box.visible = false
			player_in_area.pick_up_item(self)
			can_be_picked_up = false

func _on_dropped():
	# When dropped, make sure it can be picked up again
	can_be_picked_up = true
	
	# Enable physics simulation
	freeze = false
	gravity_scale = 1.0
	sleeping = false
		
