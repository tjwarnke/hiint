extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var book_taken = false

# UI elements - will be set in _ready
var text_box = null
var dialogue = null
var book = null

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	# Try to find UI elements in the scene tree
	text_box = get_node_or_null("../../UI/TextBoxMiddleTop")
	dialogue = get_node_or_null("../../UI/DialogOptions")
	book = get_node_or_null("../../Book")
	
	if not text_box:
		push_warning("TextBoxMiddleTop not found in scene")
	if not dialogue:
		push_warning("DialogOptions not found in scene")
	if not book:
		push_warning("Book not found in scene")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		player = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		await get_tree().create_timer(1.5).timeout

func grab_item(response):
	if dialogue:
		dialogue.visible = false
	if text_box:
		text_box.text = response
		text_box.visible = true
	dialogue_active = false
	if player and book:
		player.pick_up_item(book)
		player.set_can_move(true)
	await get_tree().create_timer(2).timeout
	if text_box:
		text_box.visible = false

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		if player:
			player.set_can_move(false)
		if dialogue:
			dialogue_active = false
			dialogue.visible = false
		
		if book_taken:
			if text_box:
				text_box.text = "You already took the book."
				text_box.visible = true
			if player:
				player.set_can_move(true)
			await get_tree().create_timer(1.5).timeout
			if text_box:
				text_box.visible = false
		else:
			if text_box:
				text_box.text = "There is a book on the shelf"
				text_box.visible = true
			if dialogue:
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
