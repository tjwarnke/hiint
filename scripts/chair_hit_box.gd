extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var talked = false
var counter = 0

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
	dialogue.visible = true
	dialogue.text = "1. Sargent Relish \n2. Magenta Lovelace \n3. Dmitri \n4. Henry Conroy \n5. Let's just eat"
func final_options():
	dialogue.visible = true
	dialogue.text = "1. This isn't funny, you have a really worried\n2. Is he dead?\n3.Good riddance, he was a jerk anyway"

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby and counter == 0:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		text.visible = true
		text.text = "Sorry about my brother, ma’am.\n My name is Diane, I’m glad you could make it."
		await get_tree().create_timer(3).timeout
		text.text = "Say:"
		dialogue.visible = true
		dialogue.text = "1. Thanks for inviting me but why are we here? \n2.Hi, I’m player character, who are you?"
		
	if event.is_action_pressed("Option6"):
		dialogue.visible = false
		text.visivle = false
		sprite.visible = false
		player.set_can_move(true)
		
	if event.is_action_pressed("Option1") and counter == 0:
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
		await get_tree().create_timer(3).timeout
		sprite.texture = con_head
		text.text = "It's a shame he passed away, he was a good man"
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "I miss him. I think that's a common feeling"
		await get_tree().create_timer(3).timeout
		sprite.texture = marvin
		text.text = "It's not the first time we missed him, sister..."
		two_a()
		counter += 1
		
	if event.is_action_pressed("Option2") and counter == 0:
		dialogue.visible = false
		text.visible = true
		sprite.texture = diane
		text.text = "This is my younger brother Marvin, \nforgive him, he’s a little… much."
		await get_tree().create_timer(3).timeout
		sprite.texture = marvin
		text.text = "By one minute"
		await get_tree().create_timer(2).timeout
		two_a()
		counter += 1
	
	if event.is_action_pressed("Option1") and counter ==1:
		dialogue.visible = false
		text.visible = true
		sprite.texture = relish_head
		text.text = "Hey there pal, my name is Sargent Relish. It’s good to meet you."
		await get_tree().create_timer(3).timeout
		two_a()
		
	if event.is_action_pressed("Option2") and counter ==1:
		dialogue.visible = false
		text.visible = true
		sprite.texture = girl_head
		text.text = " Sup girlie, I’m Magenta Lovelace. I like your hair, I can braid it later if you want. "
		await get_tree().create_timer(3).timeout
		two_a()
	if event.is_action_pressed("Option3") and counter ==1:
		dialogue.visible = false
		text.visible = true
		sprite.texture = penguins_head
		text.text = "Da, We is Dmitri. I come to mansion for dinner party. "
		await get_tree().create_timer(3).timeout
		two_a()
	if event.is_action_pressed("Option4") and counter ==1:
		dialogue.visible = false
		text.visible = true
		sprite.texture = con_head
		text.text = "Pleasure to meet you, sir. I am the esteemed Henry Conroy. I used to know your father actually. "
		await get_tree().create_timer(3).timeout
		two_a()
		
	if event.is_action_pressed("Option5") and counter ==1:
		counter += 1
		dialogue.visible = false
		text.visible = true
		sprite.texture = butler
		text.text = "And I’m the butler, here to buttle and such. If you need any buttling, I will be here. On that note, let's eat"
		await get_tree().create_timer(3).timeout
		text.visible = false
		await get_tree().create_timer(5).timeout
		text.visible = true
		text.text = "I see you are all getting along nicely. I hope to see that continue."
		await get_tree().create_timer(3).timeout
		#kill_marvin()
		sprite.texture = girl_head
		text.text = "Good heavens, sir are you ok?"
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "Marvy, quit messing around"
		await get_tree().create_timer(3).timeout
		sprite.texture = marvin
		text.text = "..."
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "Marvin!"
		await get_tree().create_timer(3).timeout
		final_options()
		
	if event.is_action_pressed("Option1") and counter == 2:
		counter += 1
		dialogue.visible = false
		text.visible = true
		sprite.texture = diane
		text.text = "Marvin..."
		await get_tree().create_timer(3).timeout
		sprite.texture = con_head
		text.text = "It doesn’t look like he’s breathing. Diane, is he ok?"
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "He’s dead. You are insensitive"
		await get_tree().create_timer(3).timeout
		sprite.texture = relish_head
		text.text = "I’m sure they didn’t mean it, Diane"
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "I’m sorry, this is all so much for me. First my father, now my brother"
		await get_tree().create_timer(3).timeout
		sprite.texture = girl_head
		text.text = "Do you need a hug, darling?"
		await get_tree().create_timer(3).timeout
		dialogue.visible = false
		text.visible = false
		sprite.visible = false
		player.set_can_move(true)
		
	if event.is_action_pressed("Option2") and counter == 2:
		counter += 1
		dialogue.visible = false
		text.visible = true
		sprite.texture = con_head
		text.text = "It doesn’t look like he’s breathing. Diane, is he ok?"
		await get_tree().create_timer(3).timeout
		sprite.texture = girl_head
		text.text = "oh dear..."
		await get_tree().create_timer(3).timeout
		dialogue.visible = false
		text.visible = false
		sprite.visible = false
		player.set_can_move(true)
	
	if event.is_action_pressed("Option3") and counter == 2:
		counter += 1
		dialogue.visible = false
		text.visible = true
		sprite.texture = penguins_head
		text.text = "Da, he was worst. Shut up Boris. Who is Boris, I am Dmitri, Marvin was not nice guy"
		await get_tree().create_timer(3).timeout
		sprite.texture = relish_head
		text.text = "Are you ok sir? Your voice sounds a little weird. "
		await get_tree().create_timer(3).timeout
		sprite.texture = penguins_head
		text.text = "Da, I am fine, it is Marvin we should be worried about."
		await get_tree().create_timer(3).timeout
		sprite.texture = girl_head
		text.text = "Oh my, he’s not breathing!"
		await get_tree().create_timer(3).timeout
		sprite.texture = relish_head
		text.text = " Diane, is he alive?"
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "Noooooooo, Marvy. How could you? You can’t die on me "
		await get_tree().create_timer(3).timeout
		dialogue.visible = false
		text.visible = false
		sprite.visible = false
		player.set_can_move(true)
	
		
		
