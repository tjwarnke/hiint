extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var talked = false

var text = null
var dialogue = null
var sprite = null

var con_head = preload("res://assets/images/conman_head.png")
var relish_head = preload("res://assets/images/relish_head.png")
var penguins_head = preload("res://assets/images/penguins_head.png")
var girl_head = preload("res://assets/images/girl_head.png")

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	text = get_node_or_null("../../UI/TextBoxMiddleTop")
	dialogue = get_node_or_null("../../UI/DialogOptions")
	sprite = get_node_or_null("../../UI/Speaker")
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		player = body
		text.visible = true
		text.text = "Press 'f' to take a seat"
		
		
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		await get_tree().create_timer(.5).timeout
		text.visible = false
		dialogue.visible = false
		
func options(response):
	dialogue.visible = false
	text.text = response
	await get_tree().create_timer(2).timeout
	
func base_dialog():
	sprite.visible = false
	dialogue.text = "1. Mysterious Trench Coater \n2. Sargent Relish \n3. Mr. Conman \n4. Girl \n5. Leave"
	dialogue.visible = true
	dialogue_active = true

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false

		if talked:
			text.text = "You already talked to everyone."
			text.visible = true
			player.set_can_move(true)
			await get_tree().create_timer(1.5).timeout
			text.visible = false
			
		else:
			text.text = "You have taken a seat at the table"
			text.visible = true
			await get_tree().create_timer(2).timeout
			text.text = "Who would you like to talk to?"
			base_dialog()
			
	if dialogue_active:
			if event.is_action_pressed("Option1"):
				sprite.scale = Vector2(.5, .5)
				sprite.texture = penguins_head
				sprite.visible = true
				text.visible = true
				dialogue.visible = false
				text.text = "Hello I am the Mysterious Trench Coater"
				await get_tree().create_timer(1.5).timeout
				text.text = "Who would you like to talk to?"
				base_dialog()
				
			if event.is_action_pressed("Option2"):
				sprite.scale = Vector2(.5, .5)
				sprite.texture = relish_head
				sprite.visible = true
				options("Hello I am Sargent Relish")
				await get_tree().create_timer(1.5).timeout
				text.text = "Who would you like to talk to?"
				base_dialog()
				
			if event.is_action_pressed("Option3"):
				sprite.scale = Vector2(.5, .5)
				sprite.texture = con_head
				sprite.visible = true
				options("Hello I am the Mr. Conman")
				await get_tree().create_timer(1.5).timeout
				sprite.visible = false
				text.text = "Who would you like to talk to?"
				base_dialog()
				
			if event.is_action_pressed("Option4"):
				sprite.scale = Vector2(.5, .5)
				sprite.texture = girl_head
				sprite.visible = true
				options("Hello I am Girl")
				await get_tree().create_timer(1.5).timeout
				sprite.visible = false
				text.text = "Who would you like to talk to?"
				base_dialog()
				
			if event.is_action_pressed("Option5"): 
				player.set_can_move(true)
				text.visible = false
				dialogue.visible = false
				dialogue_active = false
