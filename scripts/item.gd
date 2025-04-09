extends Area2D

var can_be_picked_up = true
var player = null

# Store original properties for debugging
var original_scale
var original_rotation
var original_position
var original_parent

@onready var text_box = get_node("/root/World/UI/TextBoxMiddleTop")

func _ready():
	# Store original properties for debugging
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
		if player:
			print("Item: Found player node")
		else:
			print("Item: Player node not found in World")
	else:
		print("Item: World node not found")

func _process(_delta):
	if player and Input.is_action_just_pressed("pick_up") and can_be_picked_up:
		print("Item: Pick up action detected")
		print("Item: Player reference valid: ", player != null)
		print("Item: Can be picked up: ", can_be_picked_up)
		can_be_picked_up = false  # Prevent multiple pickups
		player.pick_up_item(self)
		print("Item: Called player.pick_up_item")
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
		if can_be_picked_up:
			text_box.visible = true
			text_box.text = "Press 'e' to pick up"

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
		text_box.visible = false

func _on_dropped():
	# This function is called when the item is dropped
	# It can be overridden by child classes to add specific behavior
	pass
