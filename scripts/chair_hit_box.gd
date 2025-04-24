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
var butler = preload("res://assets/images/ButlerHead.png")
var diane = preload("res://assets/images/twin1_head.png")
var marvin = preload("res://assets/images/victim_head.png")

var page = 0

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
		sprite.visible = true
		sprite.texture = marvin
		text.text = "Well you finally made it. \nPress 'e' to sit with us."
		
		
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		await get_tree().create_timer(.5).timeout
		text.visible = false
		dialogue.visible = false
		sprite.visble = false
		
func options(response):
	dialogue.visible = false
	text.visible = true
	text.text = response
	await get_tree().create_timer(2).timeout
	
func base_dialog():
	sprite.visible = false
	dialogue.text = "6. Leave"
	dialogue.visible = true
	dialogue_active = true
	if page == 1:
		page -= 1
		
func two_a():
	dialogue.visble = true
	dialogue.text = "1. Sargent Relish \n2. Magenta Lovelace \n3. Dmitri \n4. Henry Conroy"

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		text.visible = true
		text.text = "Sorry about my brother, ma’am. \nMy name is Diane, I’m glad you could make it."
		dialogue.visible = true
		dialogue.text = "1. Thanks for inviting me but why are we here? \n2.Hi, I’m player character, who are you? \n3. I hate you and want to murder you"
		
		if event.is_action_pressed("Option6"):
			dialogue.visible = false
			text.visivle = false
			sprite.visible = false
			player.set_can_move(true)

			
		if event.is_action_pressed("Option1"):
			dialogue.visible = false
			text.visible = true
			sprite.texture = marvin
			text.text = "Didn’t you get the letter, it should explain everything"
			await get_tree().create_timer(3).timeout
			sprite.texture = girl_head
			text.text = "I was wondering why we were here too. \nThe letter was very vague."
			await get_tree().create_timer(3).timeout
			sprite.texture = relish_head
			text.text = "My daughter was telling me about this place. \nI’m thankful to be one of the community members invited"
			base_dialog()
			
			if event.is_action_pressed("Option2"):
				dialogue.visible = false
				text.visible = true
				sprite.texture = diane
				text.text = "This is my younger brother Marvin, \nforgive him, he’s a little… much."
				await get_tree().create_timer(3).timeout
				sprite.texture = marvin
				text.text = "By one minute"
				await get_tree().create_timer(2).timeout
