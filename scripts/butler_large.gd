extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var cut_scene_seen = false

@onready var text = get_node("/root/World/UI/TextBoxMiddleTop")
@onready var sprite = get_node("/root/World/UI/Speaker")

var con_head = preload("res://assets/images/conman_head.png")
var relish_head = preload("res://assets/images/relish_head.png")
var penguins_head = preload("res://assets/images/penguins_head.png")
var girl_head = preload("res://assets/images/girl_head.png")
var butler = preload("res://assets/images/ButlerHead.png")
var twin1 = preload("res://assets/images/twin1_head.png")
var twin2 = preload("res://assets/images/victim_head.png")

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		if cut_scene_seen == false:
			# Store player reference
			player = body
			
			# Prevent player movement during the cutscene
			if player.has_method("set_can_move"):
				player.set_can_move(false)
			
			# Run the butler dialog sequence
			play_butler_dialog()

# Separate function to handle the dialog sequence
func play_butler_dialog():
	sprite.scale = Vector2(.5, .5)
	player_nearby = true
	sprite.texture = butler
	sprite.visible = true
	text.visible = true
	
	# First dialog
	text.text = "Welcome to the Castle Kuznetsov."
	await get_tree().create_timer(2).timeout

		
	text.text = "Take a seat at the table!"
	await get_tree().create_timer(2).timeout
	
	
	text.text = "I can take your things, \nyou won’t be needing them here. \nEveryone else is waiting for you at the table, \nmiss-ter?.. my friend."
	
	# Remove powerups when mentioned
	if player.has_method("remove_powerups"):
		player.remove_powerups()
	
	await get_tree().create_timer(3).timeout
	sprite.texture = twin2
	text.text = "Is this guy going to get here soon? \nI’m hungry!"
	await get_tree().create_timer(2).timeout
	
	sprite.texture = twin1
	text.text = "Be patient, I’m sure she’ll be here soon"
	await get_tree().create_timer(3).timeout
	
	# End the dialog sequence
	end_dialog()

# End the dialog sequence and restore player movement
func end_dialog():
	text.visible = false
	sprite.visible = false
	cut_scene_seen = true
	
	# Allow player movement only after the cutscene
	if is_instance_valid(player) and player.has_method("set_can_move"):
		player.set_can_move(true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _on_player_entered(body):
	if body.is_in_group("player"):
		player = body
		if player.has_torch:
			# Tell player to drop torch
			player.drop_torch.emit()
		else:
			# Skip torch dialog
			pass
