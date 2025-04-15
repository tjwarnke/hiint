extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var cut_scene_seen = false

@onready var text = get_node("/root/World/UI/TextBoxMiddleTop")
@onready var sprite = get_node("/root/World/UI/Speaker")

var butler = preload("res://assets/images/ButlerHead.png")

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
	text.text = "Welcome to the Kusnetzov Mansion!"
	await get_tree().create_timer(2).timeout
	
	# Check if player reference is still valid
	if not is_instance_valid(player):
		end_dialog()
		return
		
	text.text = "Take a seat at the table!"
	await get_tree().create_timer(2).timeout
	
	# Check if player reference is still valid
	if not is_instance_valid(player):
		end_dialog()
		return
	
	text.text = "I'm afraid you cannot take your \npowerups into the mansion."
	
	# Remove powerups when mentioned
	if player.has_method("remove_powerups"):
		player.remove_powerups()
	
	await get_tree().create_timer(2.5).timeout
	
	# Check if player reference is still valid
	if not is_instance_valid(player):
		end_dialog()
		return
	
	# Do a more robust check for torch
	var has_torch = false
	
	# First check direct method
	if player.has_method("has_item"):
		has_torch = player.has_item("Torch")
	
	# If that fails, check held items directly
	if not has_torch and "held_items" in player:
		for item in player.held_items:
			if item.name.contains("Torch"):
				has_torch = true
				break
	
	# Only tell them to put down torch if they actually have one
	if has_torch:
		print("Player has torch - telling them to drop it")
		# Drop torch at exact time it's mentioned
		text.text = "Please set down your torch."
		
		# Check if player has a torch and make them drop it
		if player.has_method("drop_item"):
			for i in range(player.held_items.size()):
				if player.held_items[i].name.contains("Torch"):
					player.switch_item(i)
					
					# Drop the torch now when it's mentioned
					player.drop_item()
					break
		
		await get_tree().create_timer(2).timeout
		
		# Check if player reference is still valid
		if not is_instance_valid(player):
			end_dialog()
			return
	else:
		print("Player does not have torch - skipping torch dialog")
	
	text.text = "The dinner will start shortly!"
	await get_tree().create_timer(2).timeout
	
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
