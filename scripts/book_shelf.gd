extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var book_taken = false

@onready var text_box = get_node("/root/World/Level/UI/TextBoxMiddleTop")
@onready var dialogue = get_node("/root/World/Level/UI/DialogOptions")
@onready var book = get_node("/root/World/Level/Book")

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

	
func grab_item(response):
	dialogue.visible = false
	text_box.text = response
	dialogue_active = false
	player.pick_up_item(book)
	player.set_can_move(true)
	await get_tree().create_timer(2).timeout
	text_box.visible = false

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		
		if book_taken:
			text_box.text = "You already took the book."
			text_box.visible = true
			player.set_can_move(true)
			await get_tree().create_timer(1.5).timeout
			text_box.visible = false
		else:
			text_box.text = "There is a book on the shelf"
			text_box.visible = true
			await get_tree().create_timer(2).timeout
			text_box.text = "Would you like to take it?"
			await get_tree().create_timer(1).timeout
			dialogue.text = "1. Yes \n2. No"
			dialogue.visible = true
			dialogue_active = true
		
	if dialogue_active:
		if event.is_action_pressed("Option1"):
			book_taken = true
			grab_item("The book has been taken")
			
		if event.is_action_pressed("Option2"):
			dialogue.visible = false
			text_box.visible = false
			player.set_can_move(true)
