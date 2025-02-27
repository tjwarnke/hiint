extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false

@onready var text_box = get_node("/root/World/Level/UI/TextBoxMiddleTop")
@onready var dialogue = get_node("/root/World/Level/UI/DialogOptions")

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		await get_tree().create_timer(1.5).timeout
		text_box.visible = false
		dialogue.visible = false

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		dialogue.visible = false
		text_box.text = "It's a me Mayro!"
		text_box.visible = true
		await get_tree().create_timer(2).timeout
		text_box.text = "Have you seen my brother?"
		await get_tree().create_timer(1).timeout
		dialogue.text = "1. The Green Guy? \n2. No I have not."
		dialogue.visible = true
		dialogue_active = true
	if dialogue_active:
		if event.is_action_pressed("Option1"):
			dialogue.visible = false
			text_box.text = "Yes! He is Here!"
			dialogue_active = false
			await get_tree().create_timer(2).timeout
			text_box.visible = false
			
		if event.is_action_pressed("Option2"):
			dialogue.visible = false
			text_box.text = "Go find him!"
			dialogue_active = false
			await get_tree().create_timer(2).timeout
			text_box.visible = false
		
