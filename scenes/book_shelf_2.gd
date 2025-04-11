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

func give_dialogue(response):
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
			text_box.text = "It looks like some books have been taken off the shelf recently"
			text_box.visible = true
			await get_tree().create_timer(2).timeout
			text_box.text = "Would you like to read any? Read:"
			await get_tree().create_timer(1).timeout
			dialogue.text = "1. Solving Puzzles - Enser Giver \n2. The Kusnetzov Mansion - Vlad Kusnetzov \n3.  The Maelstrom's Eye - Roger E Moore"
			dialogue.visible = true
			dialogue_active = true
		
	if dialogue_active:
		if event.is_action_pressed("Option1"):
			#This texxt should be changed cause it sucks
			give_dialogue("The book gives resistance when yanked")
			$library.drop_books()
		if event.is_action_pressed("Option2"):
			give_dialogue("You read of the dissapearance of many people from the nearby neighborhood, and how many assumed they were to be found in the mansion. The leading theory being a hidden dungeon beneath the castle")
		if event.is_action_pressed("Option3"):
			give_dialogue("You read of a race called the Dohwar, who were three foot avians not unlike penguins. You write this off as fiction")
