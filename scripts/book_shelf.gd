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
		text_box.visible = false
		dialogue.visible = false

func grab_item(response):
	dialogue.visible = false
	text_box.text = response
	dialogue_active = false
	
	# Make the existing book physically interactive
	if book:
		# Make sure the book is visible
		book.visible = true
		
		# Enable physics on the book if it's a RigidBody2D
		if book is RigidBody2D:
			book.freeze = false
			book.sleeping = false
			book.gravity_scale = 1.0
			book.can_be_picked_up = true
			
			# Make sure collision is enabled
			var collision = book.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = false
	
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
