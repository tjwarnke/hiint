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
var dark = null
var marvin_dead = null
var marvin_alive = null
var intro_complete = false
var guess_time = false

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
	dark =  get_node_or_null("../../DiningRoom/Black")
	marvin_alive = get_node_or_null("../../DiningRoom/Twin1")
	marvin_dead = get_node_or_null("../../DiningRoom/Twin1Dead")
	
func _on_body_entered(body):
	if body.is_in_group("player") and counter ==0:
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
		sprite.visible = false

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
	await get_tree().create_timer(1).timeout
	dialogue.visible = true
	text.text = "Talk to:"
	dialogue.text = "1. Sargent Relish \n2. Magenta Lovelace \n3. Dmitri \n4. Henry Conroy \n5. Let's just eat"
func final_options():
	await get_tree().create_timer(1).timeout
	text.text = "Say:"
	dialogue.visible = true
	dialogue.text = "1. This isn't funny, you have me really worried\n2. Is he dead?\n3. Good riddance, he was a jerk anyway"
func guess_killer():
	sprite.visible = false
	guess_time = true
	text.visible = true
	text.text = "Who killed Marvin"
	dialogue.visible = true
	dialogue.text = "1. Dmitri \n2. Sargent Relish \n3. Henry Conroy \n4. Magenta Lovelace \n5. Butler \n6. Diane"

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby and counter == 0:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		text.visible = true
		sprite.texture = diane
		text.text = "Sorry about my brother,\nma’am. My name is Diane,\n I’m glad you could make it."
		await get_tree().create_timer(3).timeout
		text.text = "Say:"
		dialogue.visible = true
		dialogue.text = "1. Thanks for inviting me but why are we here?\n2. Hi, who are you?"
		counter += 1

	if event.is_action_pressed("Option1") and counter == 1:
		dialogue.visible = false
		text.visible = true
		sprite.texture = marvin
		text.text = "Didn’t you get the letter,\nit should explain everything"
		await get_tree().create_timer(3).timeout
		sprite.texture = girl_head
		text.text = "I was wondering why we\n were here too. The letter was\nvery vague."
		await get_tree().create_timer(3).timeout
		sprite.texture = relish_head
		text.text = "My daughter was telling me about \nthis place. I’m thankful to\nbe one of the community members invited"
		await get_tree().create_timer(3).timeout
		sprite.texture = con_head
		text.text = "It's a shame he passed away,\nhe was a good man"
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "I miss him. I think that's\na common feeling"
		await get_tree().create_timer(3).timeout
		sprite.texture = marvin
		text.text = "It's not the first time\nwe missed him, sister..."
		counter += 1
		two_a()

	if event.is_action_pressed("Option2") and counter == 1:
		dialogue.visible = false
		text.visible = true
		sprite.texture = diane
		text.text = "This is my younger brother Marvin,\nforgive him, he’s a little… much."
		await get_tree().create_timer(3).timeout
		sprite.texture = marvin
		text.text = "By one minute"
		await get_tree().create_timer(2).timeout
		text.visible = false
		two_a()

	if event.is_action_pressed("Option1") and counter ==2:
		dialogue.visible = false
		text.visible = true
		sprite.texture = relish_head
		text.text = "Hey there pal, my name is Sargent\nRelish. It’s good to meet you."
		await get_tree().create_timer(3).timeout
		two_a()

	if event.is_action_pressed("Option2") and counter ==2:
		dialogue.visible = false
		text.visible = true
		sprite.texture = girl_head
		text.text = " Sup girlie, I’m Magenta Lovelace.\nI like your hair, I can braid \nit later if you want. "
		await get_tree().create_timer(3).timeout
		two_a()
	if event.is_action_pressed("Option3") and counter ==2:
		dialogue.visible = false
		text.visible = true
		sprite.texture = penguins_head
		text.text = "Da, We is Dmitri. I come to\nmansion for dinner party. "
		await get_tree().create_timer(3).timeout
		two_a()
	if event.is_action_pressed("Option4") and counter ==2:
		dialogue.visible = false
		text.visible = true
		sprite.texture = con_head
		text.text = "Pleasure to meet you, sir.\nI am the esteemed Henry Conroy.\nI used to know your father actually. "
		await get_tree().create_timer(3).timeout
		two_a()

	if event.is_action_pressed("Option5") and counter ==2:
		counter += 1
		dialogue.visible = false
		text.visible = true
		sprite.texture = butler
		text.text = "And I’m the butler, here to buttle and such.\nIf you need any buttling, I will be here.\nOn that note, let's eat"
		await get_tree().create_timer(5).timeout
		text.visible = false
		await get_tree().create_timer(2).timeout
		text.visible = true
		text.text = "I see you are all getting along nicely.\nI hope to see that continue."
		await get_tree().create_timer(3).timeout
		death_scene()
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

	if event.is_action_pressed("Option1") and counter == 3:
		counter += 1
		dialogue.visible = false
		text.visible = true
		sprite.texture = diane
		text.text = "Marvin..."
		await get_tree().create_timer(3).timeout
		sprite.texture = con_head
		text.text = "It doesn’t look like he’s breathing.\nDiane, is he ok?"
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "He’s dead. You are insensitive"
		await get_tree().create_timer(3).timeout
		sprite.texture = relish_head
		text.text = "I’m sure they didn’t mean it, Diane"
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "I’m sorry, this is all so much for me.\nFirst my father, now my brother"
		await get_tree().create_timer(3).timeout
		sprite.texture = girl_head
		text.text = "Do you need a hug, darling?"
		await get_tree().create_timer(3).timeout
		sprite.texture = butler
		text.text = "Player, it is your job to fild the killer\n Go now!"
		await get_tree().create_timer(3).timeout
		dialogue.visible = false
		text.visible = false
		sprite.visible = false
		player.set_can_move(true)
		intro_complete = true

	if event.is_action_pressed("Option2") and counter == 3:
		counter += 1
		dialogue.visible = false
		text.visible = true
		sprite.texture = con_head
		text.text = "It doesn’t look like he’s breathing.\nDiane, is he ok?"
		await get_tree().create_timer(3).timeout
		sprite.texture = girl_head
		text.text = "oh dear..."
		await get_tree().create_timer(3).timeout
		sprite.texture = butler
		text.text = "Player, it is your job to fild the killer\n Go now!"
		await get_tree().create_timer(3).timeout
		dialogue.visible = false
		text.visible = false
		sprite.visible = false
		player.set_can_move(true)
		intro_complete = true

	if event.is_action_pressed("Option3") and counter == 3:
		counter += 1
		dialogue.visible = false
		text.visible = true
		sprite.texture = penguins_head
		text.text = "Da, he was worst. Shut up Boris.\nWho is Boris, I am Dmitri,\nMarvin was not nice guy"
		await get_tree().create_timer(3).timeout
		sprite.texture = relish_head
		text.text = "Are you ok sir?\nYour voice sounds a little weird. "
		await get_tree().create_timer(3).timeout
		sprite.texture = penguins_head
		text.text = "Da, I am fine, it is\nMarvin we should be worried about."
		await get_tree().create_timer(3).timeout
		sprite.texture = girl_head
		text.text = "Oh my, he’s not breathing!"
		await get_tree().create_timer(3).timeout
		sprite.texture = relish_head
		text.text = " Diane, is he alive?"
		await get_tree().create_timer(3).timeout
		sprite.texture = diane
		text.text = "Noooooooo, Marvy. How could you?\nYou can’t die on me "
		await get_tree().create_timer(3).timeout
		sprite.texture = butler
		text.text = "Player, it is your job to fild the killer\n Go now!"
		await get_tree().create_timer(3).timeout
		dialogue.visible = false
		text.visible = false
		sprite.visible = false
		player.set_can_move(true)
		intro_complete = true
		
	if event.is_action_pressed("Interact2") and in_chair2 == true:
		sprite.visible = true
		sprite.texture = butler
		text.visible = true
		text.text = "Player, tell us who the killer is"
		await get_tree().create_timer(3).timeout
		sprite.visible = false
		guess_killer()
		
	if in_chair2 and guess_time and event.is_action_pressed("Option1"):
		dialogue.visible = false
		sprite.visible = true
		sprite.texture = penguins_head
		text.text = "Uhhh. We... I mean I did not kill him"
		await get_tree().create_timer(3).timeout
		guess_killer()
	
	if in_chair2 and guess_time and event.is_action_pressed("Option2"):
		dialogue.visible = false
		sprite.visible = true
		sprite.texture = relish_head
		text.text = "I never thought you would catch me\n These fake medals... \n I knew I shouldn't have worn them"
		await get_tree().create_timer(3).timeout
		player.set_can_move(true)
		text.text = "You have guessed the correct killer"
		await get_tree().create_timer(3).timeout
		text.text = "Congrats!!!"
		
	if in_chair2 and guess_time and event.is_action_pressed("Option3"):
		dialogue.visible = false
		sprite.visible = true
		sprite.texture = con_head
		text.text = "I may not be trustworthy... \nBut I would never kill anyone"
		await get_tree().create_timer(3).timeout
		guess_killer()
		
	if in_chair2 and guess_time and event.is_action_pressed("Option4"):
		dialogue.visible = false
		sprite.visible = true
		sprite.texture = girl_head
		text.text = "Why would I kill a person?\n I would not hurt a fly!"
		await get_tree().create_timer(3).timeout
		guess_killer()
		
	if in_chair2 and guess_time and event.is_action_pressed("Option5"):
		dialogue.visible = false
		sprite.visible = true
		sprite.texture = butler
		text.text = "I have no tme for such cruel things\n I have been busy buttling!"
		await get_tree().create_timer(3).timeout
		guess_killer()
		
	if in_chair2 and guess_time and event.is_action_pressed("Option6"):
		dialogue.visible = false
		sprite.visible = true
		sprite.texture = diane
		text.text = "ME? Kill my OWN brother?!?!"
		await get_tree().create_timer(3).timeout
		guess_killer()
		

func death_scene():
	text.visible = false
	sprite.visible = false
	dialogue.visible = false
	dark.visible = true
	await get_tree().create_timer(.2).timeout
	dark.visible = false
	await get_tree().create_timer(.2).timeout
	dark.visible = true
	await get_tree().create_timer(.2).timeout
	dark.visible = false
	await get_tree().create_timer(.2).timeout
	dark.visible = true
	text.visible = true
	text.text = "AHHHHHHHHHHHHHHH"
	marvin_alive.visible = false
	marvin_dead.visible = true
	await get_tree().create_timer(2).timeout
	dark.visible = false
	sprite.visible = true
	
var in_chair2 = false
func _on_chair_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and intro_complete == true:
		player_nearby = true
		player = body
		in_chair2 = true
		sprite.visible = true
		sprite.texture = butler
		text.visible = true
		text.text = "You made it back!. \nPress 'e' to sit with us."

func _on_chair_2_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		await get_tree().create_timer(.5).timeout
		text.visible = false
		dialogue.visible = false
		sprite.visible = false
