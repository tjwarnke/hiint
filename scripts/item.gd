extends Area2D

signal item_picked

var can_be_picked_up = true
var player = null
var player_in_area = false  # Track when player is in the item's area

# Store original properties for debugging
var original_scale = Vector2.ZERO
var original_rotation = 0.0
var original_position = Vector2.ZERO
var original_parent = null

@onready var text_box = get_node("/root/World/UI/TextBoxMiddleTop")
@onready var sprite = $Sprite2D

func _ready():
	add_to_group("item")
	# Store original properties
	original_scale = scale
	original_rotation = rotation
	original_position = position
	original_parent = get_parent()
	
	# Wait for the Player node to be available
	await get_tree().process_frame
	await get_tree().process_frame  # Wait two frames to ensure World is ready
	
	# Try to find the player node
	var world = get_node_or_null("/root/World")
	if world:
		player = world.get_node_or_null("Player")

func _process(_delta):
	if player and Input.is_action_just_pressed("pick_up") and can_be_picked_up and player_in_area:
		can_be_picked_up = false  # Prevent multiple pickups
		emit_signal("item_picked")
		player.pick_up_item(self)
		# Don't free the item here - let the player handle it

func _on_player_powerup_ready(powerup_name, value):
	if powerup_name == "Jump":
		# Handle jump powerup
		pass
	elif powerup_name == "Dash":
		# Handle dash powerup
		pass

func _on_player_powerup_used(powerup_name):
	if powerup_name == "Jump":
		# Handle jump powerup used
		pass
	elif powerup_name == "Dash":
		# Handle dash powerup used
		pass

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		player_in_area = true  # Set player_in_area to true when player enters
		if can_be_picked_up:
			text_box.visible = true
			text_box.text = "Press 'e' to pick up"

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
		player_in_area = false  # Set player_in_area to false when player exits
		text_box.visible = false

func _on_dropped():
	# This function is called when the item is dropped
	# Reset to original scale
	scale = original_scale
	rotation = original_rotation
	
	# Make sure the item is visible and can be picked up again
	visible = true
	can_be_picked_up = true
	
	# Reset the player reference and area state
	player = null
	player_in_area = false
