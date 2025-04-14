extends Area2D

signal item_picked

var can_be_picked_up = true
var player = null
var player_in_area = null
var light_intensity = 1.0  # Reduced from 1.5 to make the light weaker
var original_scale = Vector2(1.0, 1.0)  # Store original scale for reference

@onready var text_box = get_node("/root/World/UI/TextBoxMiddleTop")
@onready var sprite = $Sprite2D
@onready var light = $PointLight2D

# Store original properties for debugging
var original_rotation = 0.0
var original_position = Vector2.ZERO
var original_parent = null

func _ready():
	# Store original scale
	original_scale = scale
	
	# Reduce light scale and intensity
	if light:
		light.scale = Vector2(0.25, 0.25)  # Smaller light
		light.energy = 0.8  # Reduced energy
		light.texture_scale = 0.5  # Shrink texture scale

	add_to_group("item")  # Add to item group for interaction
	
	# Store original properties
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
	if player_in_area and Input.is_action_just_pressed("pick_up") and can_be_picked_up:
		text_box.visible = false
		can_be_picked_up = false  # Prevent multiple pickups
		
		# Call the player's pick_up_item function with this torch
		if player and player.has_method("pick_up_item"):
			player.pick_up_item(self)

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
		player_in_area = body
		if can_be_picked_up:
			text_box.visible = true
			text_box.text = "Press 'e' to pick up torch"

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
		player_in_area = null
		text_box.visible = false

# Called when the torch is dropped
func _on_dropped():
	# Reset torch properties when dropped
	can_be_picked_up = true
	
	# Make sure the light is at the correct scale when dropped
	if light:
		light.scale = Vector2(0.25, 0.25)  # Keep the smaller light scale
		light.energy = 0.8  # Reduced energy
		light.texture_scale = 0.5  # Maintain smaller texture scale
	
	# Reset the player reference
	player = null
	player_in_area = null
	
	# Reset the torch's properties to the correct values
	scale = Vector2(1.0, 1.0)  # Use consistent scale of 1.0
	rotation = 0  # Reset rotation to upright
	
	# Reset the PointLight2D scale to ensure proper light shape
	if light:
		light.scale = Vector2(0.25, 0.25)  # Even smaller light (was 0.4)
		light.energy = 0.8  # Reduced energy
		light.texture_scale = 0.5  # Smaller texture scale (was 0.7)
	
	# Make sure the torch is visible and can be picked up again
	visible = true
	print("TORCH DEBUG: Final scale after _on_dropped: ", scale) 
