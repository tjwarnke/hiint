extends Area2D

signal item_picked

var can_be_picked_up = true
var player = null
var player_in_area = null
var light_intensity = 1.0  # Reduced from 1.5 to make the light weaker
var original_scale = Vector2(1.0, 1.0)  # Store original scale for reference
var is_held = false
var is_dropped = false

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
	
	# Connect signals
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Initialize state
	is_held = false
	is_dropped = false
	
	# Set initial collision state
	update_collision_state()
	
	# Connect to player's drop signal if we can find the player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("drop_torch"):
		player.drop_torch.connect(_on_dropped)

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
	is_held = false
	is_dropped = true
	update_collision_state()
	
	# Reset scale to original
	scale = original_scale
	
	# Reset the player reference
	player = null
	player_in_area = null
	
	# Reset the torch's properties to the correct values
	rotation = 0  # Reset rotation to upright
	
	# Reset the PointLight2D scale to ensure proper light shape
	if light:
		light.scale = Vector2(0.25, 0.25)  # Even smaller light (was 0.4)
		light.energy = 0.8  # Reduced energy
		light.texture_scale = 0.5  # Smaller texture scale (was 0.7)
	
	# Make sure the torch is visible and can be picked up again
	visible = true
	can_be_picked_up = true

# Update collision state based on whether the torch is held or dropped
func update_collision_state():
	if is_held:
		# When held, disable collision
		collision_layer = 0
		collision_mask = 0
	else:
		# When dropped, enable collision
		collision_layer = 1
		collision_mask = 1
