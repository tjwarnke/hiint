extends Area2D

signal torch_picked

@onready var text_box = get_node("/root/World/UI/TextBoxMiddleTop")
@onready var sprite = $Sprite2D
@onready var light = $PointLight2D

var can_be_picked_up = true
var player = null
var player_in_area = false  # Track when player is in the torch's area

# Store original properties for debugging
var original_scale = Vector2.ZERO
var original_rotation = 0.0
var original_position = Vector2.ZERO
var original_parent = null

func _ready():
	add_to_group("item")
	# Store original properties
	original_scale = scale
	original_rotation = rotation
	original_position = position
	original_parent = get_parent()
	print("TORCH DEBUG: Initial scale in _ready: ", scale)
	print("TORCH DEBUG: Original scale stored: ", original_scale)
	
	# Wait for the Player node to be available
	await get_tree().process_frame
	await get_tree().process_frame  # Wait two frames to ensure World is ready
	
	# Try to find the player node
	var world = get_node_or_null("/root/World")
	if world:
		player = world.get_node_or_null("Player")

func _process(_delta):
	if player and Input.is_action_just_pressed("pick_up") and can_be_picked_up and player_in_area:
		print("TORCH DEBUG: Scale before pickup: ", scale)
		can_be_picked_up = false  # Prevent multiple pickups
		emit_signal("torch_picked")
		player.pick_up_item(self)
		print("TORCH DEBUG: Scale after pickup signal: ", scale)
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
	print("TORCH DEBUG: Scale before _on_dropped: ", scale)
	# Set the torch's properties to the correct values
	scale = Vector2(1.0, 1.0)  # Use consistent scale of 1.0
	print("TORCH DEBUG: Scale after setting in _on_dropped: ", scale)
	rotation = 0  # Reset rotation to upright
	
	# Reset the PointLight2D scale to ensure proper light shape
	if light:
		light.scale = Vector2(1.0, 1.0)  # Set light scale to 1.0, 1.0
		print("TORCH DEBUG: Light scale after reset: ", light.scale)
	
	# Make sure the torch is visible and can be picked up again
	visible = true
	can_be_picked_up = true
	
	# Reset the player reference and area state
	player = null
	player_in_area = false
	print("TORCH DEBUG: Final scale after _on_dropped: ", scale) 
