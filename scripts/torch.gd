extends Area2D

signal torch_picked

@onready var text_box = $TextBox
@onready var text_label = $TextBox/Label
@onready var sprite = $Sprite2D
@onready var light = $PointLight2D

var can_be_picked_up = true
var player = null

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
			emit_signal("torch_picked")
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
			text_box.visible = true
			text_label.text = "Press 'e' to pick up"

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
		text_box.visible = false
