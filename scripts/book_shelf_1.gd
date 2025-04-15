extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
#var book_lever = false
var is_on = false # Tracks the state of the lever


# UI elements - will be set in _ready
var text_box = null
var dialogue = null
var book = null
var platform = null 
func _ready():
	platform = get_parent().get_node("Platform")
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	# Make sure platform starts disabled
	if platform and platform.has_method("set_enabled"):
		platform.set_enabled(false)
	elif platform and "enabled" in platform:
		platform.enabled = false
	
	# Try to find UI elements in the scene tree
	text_box = get_node_or_null("../../UI/TextBoxMiddleTop")
	dialogue = get_node_or_null("../../UI/DialogOptions")
	
	if not text_box:
		push_warning("TextBoxMiddleTop not found in scene")
	if not dialogue:
		push_warning("DialogOptions not found in scene")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		player = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		await get_tree().create_timer(1.5).timeout
		text_box.visible = false
		dialogue.visible = false

func give_dialogue(response):
	dialogue.visible = false
	text_box.text = response
	dialogue_active = false
	#player.pick_up_item(book)
	player.set_can_move(true)
	await get_tree().create_timer(2).timeout
	text_box.visible = false


func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		
		#if book_taken:
			#text_box.text = "You already took the book."
			#text_box.visible = true
			#player.set_can_move(true)
			#await get_tree().create_timer(1.5).timeout
			#text_box.visible = false
		
		
		text_box.text = "Some books on the shelf stand out, having fingerprints in the dust"
		text_box.visible = true
		await get_tree().create_timer(2).timeout
		text_box.text = "Would you like to read any? Read:"
		await get_tree().create_timer(1).timeout
		dialogue.text = "1. The Kusnetzov Family - Nana Kusnetsov \n2. Surprise! - Abuton Press \n3. Goosebumps - RL Stein"
		dialogue.visible = true
		dialogue_active = true
		
	if dialogue_active:
		if event.is_action_pressed("Option1"):
			#This texxt should be changed cause it sucks
			give_dialogue("\"The Kusnetzov family rose to power in the early 1700s. \nIn 1845, I became the first to move to america, the my younger siblings following soon after\"")
		if event.is_action_pressed("Option2"):
			give_dialogue("You feel a click as you pull on the book. It seems to be hiding something...")
			reveal_platform()
		if event.is_action_pressed("Option3"):
			give_dialogue("A classic, you laugh, you get scared, then you remember you should be chasing the killer")
			
func reveal_platform():
	if not platform:
		push_warning("Platform not found!")
		return
		
	# Toggle platform state
	if is_on:
		# Disable platform
		if platform.has_method("set_enabled"):
			platform.set_enabled(false)
		else:
			platform.enabled = false
		
		# Play sound effect if available
		var sound = get_node_or_null("DisableSound")
		if sound:
			sound.play()
			
		# Visual feedback
		text_box.text = "The platform disappears!"
		text_box.visible = true
		await get_tree().create_timer(1.0).timeout
		text_box.visible = false
	else:
		# Enable platform
		if platform.has_method("set_enabled"):
			platform.set_enabled(true)
		else:
			platform.enabled = true
		
		# Play sound effect if available
		var sound = get_node_or_null("EnableSound")
		if sound:
			sound.play()
			
		# Visual feedback
		text_box.text = "A hidden platform appears!"
		text_box.visible = true
		await get_tree().create_timer(1.0).timeout
		text_box.visible = false
		
	# Toggle state
	is_on = !is_on
	
