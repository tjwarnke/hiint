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
var twin1 = preload("res://assets/images/twin1_head.png")
var twin2 = preload("res://assets/images/victim_head.png")

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
		sprite.texture = twin2
		text.text = "Well you finally made it. Press 'e' to sit with us."
		
		
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		await get_tree().create_timer(.5).timeout
		text.visible = false
		dialogue.visible = false
		
func options(response):
	dialogue.visible = false
	text.visible = true
	text.text = response
	await get_tree().create_timer(2).timeout
	
func base_dialog():
	sprite.visible = false
	dialogue.text = "1. Mysterious Trench Coater \n2. Sargent Relish \n3. Mr. Conman \n4. Girl \n5. Next \n6. Leave"
	dialogue.visible = true
	dialogue_active = true
	if page == 1:
		page -= 1

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		text.text = "Welcome to the Castle Kuznetsov. I can take your things, you won’t be needing them here. \nEveryone else is waiting for you at the table, miss-ter?.. my friend."
		text.visible = true
		sprite.texture = butler
		await get_tree().create_timer(3).timeout
		
		
		
		
