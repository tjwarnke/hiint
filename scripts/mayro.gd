extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null

@onready var text_box = get_node("/root/World/Level/UI/TextBoxMiddleTop")
@onready var dialogue = get_node("/root/World/Level/UI/DialogOptions")
@onready var sprite = get_node("/root/World/Level/UI/Speaker")
@onready var Box1 = get_node("/root/World/Level/UI/TextBoxMiddleTopBack")
@onready var Box2 = get_node("/root/World/Level/UI/TextBoxMiddleTopBack2")
var mayro = preload("res://assets/images/MayroHead.png")

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	

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
		sprite.visible = false
		Box1.visible = false
	
func dialogue_choose(response):
	dialogue.visible = false
	text_box.text = response
	dialogue_active = false
	player.set_can_move(true)
	await get_tree().create_timer(2).timeout
	text_box.visible = false
	sprite.visible = false
	Box1.visible = false
	Box2.visible = false

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		sprite.scale = Vector2(0.25, 0.25)
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		Box1.visible = true
		sprite.texture = mayro
		sprite.visible = true
		text_box.text = "It's a me Mayro!"
		text_box.visible = true
		await get_tree().create_timer(2).timeout
		text_box.text = "Have you seen my brother?"
		await get_tree().create_timer(1).timeout
		Box2.visible = true
		dialogue.text = "1. The Green Guy? \n2. No I have not."
		dialogue.visible = true
		dialogue_active = true
		
	if dialogue_active:
		if event.is_action_pressed("Option1"):
			dialogue_choose("Yes! He is Here!")
			
		if event.is_action_pressed("Option2"):
			dialogue_choose("Go find him!")
