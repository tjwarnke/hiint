extends Node2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var books_dropped = false

# UI elements - will be set in _ready
var text_box = null
var dialogue = null

# Autobiography books
var annas = null
var vlads = null
var nanas = null

# Book content for reading
var book_contents = {
	"Anna_Autobiography": "\"Dear Diary, I suspected something was off about Vlad from the beginning. \nThe way he would disappear at night, the strange noises from the basement. I fear what I might discover if I investigate further...\"",
	"Vlad_Autobiography": "\"Upon Alena's death, Anna and I fought over who would inherit the mansion. \nAs the first twin to see the light, I claimed birthright. The family secrets must remain hidden in these walls.\"",
	"Nana_Autobiography": "\"The Kusnetzov family rose to power in the early 1700s. In 1845, I became the first to move to America, with my younger siblings following soon after. \nOur family's gifts must be protected at all costs.\""
}

func _ready():
	annas = get_parent().get_node("Anna_Autobiography")
	vlads = get_parent().get_node("Vlad_Autobiography")
	nanas = get_parent().get_node("Nana_Autobiography")
	
	# Set up the autobiography books
	setup_book(annas)
	setup_book(vlads)
	setup_book(nanas)
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	# Try to find UI elements in the scene tree
	text_box = get_node_or_null("../../UI/TextBoxMiddleTop")
	dialogue = get_node_or_null("../../UI/DialogOptions")
	
	if not text_box:
		push_warning("TextBoxMiddleTop not found in scene")
	if not dialogue:
		push_warning("DialogOptions not found in scene")

# Setup each book with correct properties for interaction
func setup_book(book):
	if book:
		# Hide initially
		book.hide()
		
		# Make sure books are in the "item" group for pickup logic
		if not book.is_in_group("item"):
			book.add_to_group("item")
		
		# Make sure the book uses can_be_picked_up property (for item.gd script)
		book.can_be_picked_up = false
			
		# If it's a RigidBody2D, freeze it and adjust physics
		if book is RigidBody2D:
			book.set_freeze_enabled(true)
			# Add book content as metadata
			var book_name = book.name
			if book_contents.has(book_name):
				book.set_meta("book_content", book_contents[book_name])
			
		# If it's an Area2D (item.gd), disable collision
		elif book is Area2D:
			var collision = book.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = true
			# Add book content as metadata
			var book_name = book.name
			if book_contents.has(book_name):
				book.set_meta("book_content", book_contents[book_name])

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
	player.set_can_move(true)
	await get_tree().create_timer(4).timeout
	text_box.visible = false

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		
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
			give_dialogue("The book gives resistance when yanked")
			drop_books()
		if event.is_action_pressed("Option2"):
			give_dialogue("\"Upon Alena's death, there was a battle between me and Anna over who would inherit the mansion. \nAs the first twin to see the light, I claimed birthright\"")
		if event.is_action_pressed("Option3"):
			give_dialogue("You read of a race called the Dohwar, who were three foot avians not unlike penguins. It seems fictional...")
			
func drop_books():
	if books_dropped:
		return
		
	books_dropped = true
	
	# Make books visible and interactive
	make_book_interactive(annas)
	make_book_interactive(vlads)
	make_book_interactive(nanas)
	
	# Play sound or animation if needed
	# play_sound()

# Make a book interactive so it can be picked up
func make_book_interactive(book):
	if book:
		# Show the book
		book.show()
		
		# Enable pickups
		book.can_be_picked_up = true
		
		# If it's a RigidBody2D, unfreeze it and set physics properties
		if book is RigidBody2D:
			book.set_freeze_enabled(false)
			# Set appropriate physics properties for movement
			book.gravity_scale = 1.0
			book.mass = 1.0
			book.linear_damp = 1.0
			# Apply a small random impulse to make books fall differently
			var random_impulse = Vector2(randf_range(-100, 100), randf_range(-50, 0))
			book.apply_impulse(random_impulse)
			
		# If it's an Area2D (item.gd), enable collision
		elif book is Area2D:
			var collision = book.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = false
