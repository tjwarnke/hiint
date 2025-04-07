extends Area2D

var can_be_picked_up = true
var player = null

# Store original properties for debugging
var original_scale
var original_rotation
var original_position
var original_parent

func _ready():
	# Store original properties for debugging
	original_scale = scale
	original_rotation = rotation
	original_position = position
	original_parent = get_parent()
	
	# Connect to the player's powerup_ready signal
	player = get_node("/root/World/Player")
	if player:
		player.powerup_ready.connect(_on_player_powerup_ready)
	
	# Connect to the player's powerup_used signal
	if player:
		player.powerup_used.connect(_on_player_powerup_used)

func _process(_delta):
	if player and player.is_in_powerup_area and player.powerup_area == self:
		if Input.is_action_just_pressed("interact") and can_be_picked_up:
			player.pick_up_item(self)
			queue_free()

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
			$TextBox.visible = true
			$TextBox/Label.text = "Press 'e' to pick up"

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
		$TextBox.visible = false

func _on_dropped():
	# This function is called when the item is dropped
	# It can be overridden by child classes to add specific behavior
	pass
