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

var annas_book = null
var vlads_book = null
var nanas_book = null

# Book content for reading
var book_contents = {
	"Anna_Autobiography": "\"Dear Diary, I suspected something was off about Vlad from the beginning.\n\nThe way he would disappear at night, the strange noises from the basement.\n\nI fear what I might discover if I investigate further...\"",
	"Vlad_Autobiography": "\"Upon Alena's death, Anna and I fought over who would inherit the mansion.\n\nAs the first twin to see the light, I claimed birthright.\n\nThe family secrets must remain hidden in these walls.\"",
	"Nana_Autobiography": "\"The Kusnetzov family rose to power in the early 1700s.\n\nIn 1845, I became the first to move to America, with my younger siblings following soon after.\n\nOur family's gifts must be protected at all costs.\""
}

func _ready():
	print_debug("Initializing bookshelf_2")
	annas = get_parent().get_node("Anna_Auto_fall")
	vlads = get_parent().get_node("Vlad_Auto_fall")
	nanas = get_parent().get_node("Nana_Auto_fall")
	
	annas_book = get_parent().get_node("Anna_Autobiography")
	vlads_book = get_parent().get_node("Vlad_Autobiography")
	nanas_book = get_parent().get_node("Nana_Autobiography")
	
	# Verify all book nodes exist
	if not annas or not vlads or not nanas:
		push_error("Missing fall book nodes in bookshelf_2")
	if not annas_book or not vlads_book or not nanas_book:
		push_error("Missing autobiography book nodes in bookshelf_2")
	
	annas_book.visible = false
	vlads_book.visible = false
	nanas_book.visible = false
	
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
	print_debug("Bookshelf_2 initialization complete")

# Setup each book with correct properties for interaction
func setup_book(book):
	if book:
		print_debug("Setting up book: ", book.name)
		# Hide initially
		book.hide()
		
		# Make sure books are in the "item" group for pickup logic
		if not book.is_in_group("item"):
			book.add_to_group("item")
			print_debug("Added book to item group: ", book.name)
		
		# If it's a RigidBody2D, freeze it and adjust physics
		if book is RigidBody2D:
			book.set_freeze_enabled(true)
			# Add book content as metadata
			var book_name = book.name
			if book_contents.has(book_name):
				book.set_meta("book_content", book_contents[book_name])
				print_debug("Set book content for: ", book_name)
			
		# If it's an Area2D (item.gd), disable collision
		elif book is Area2D:
			var collision = book.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = true
			# Add book content as metadata
			var book_name = book.name
			if book_contents.has(book_name):
				book.set_meta("book_content", book_contents[book_name])
				print_debug("Set book content for: ", book_name)
	else:
		push_warning("Attempted to setup null book in bookshelf_2")

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
	await get_tree().create_timer(10.0).timeout  # Increased from 4 seconds
	text_box.visible = false
	dialogue_active = false  # Ensure dialogue state is reset

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		
		# Show initial text
		text_box.text = "It looks like some books have been taken off the shelf recently"
		text_box.visible = true
		
		# Create a timer for the text change
		var timer = get_tree().create_timer(2.0)
		await timer.timeout
		
		# Check if the player is still nearby before continuing
		if player_nearby:
			text_box.text = "Would you like to read any? Read:"
			
			# Create another timer for the dialogue
			timer = get_tree().create_timer(1.0)
			await timer.timeout
			
			# Check if the player is still nearby before showing dialogue
			if player_nearby:
				dialogue.text = "1. Solving Puzzles - Enser Giver \n2. The Kusnetzov Mansion - Vlad Kusnetzov \n3.  The Maelstrom's Eye - Roger E Moore"
				dialogue.visible = true
				dialogue_active = true
				print_debug("Showing book selection dialogue")
	
	if dialogue_active:
		if event.is_action_pressed("Option1"):
			give_dialogue("The book gives resistance when yanked")
			drop_books()
		if event.is_action_pressed("Option2"):
			give_dialogue("\"Upon Alena's death, there was a battle between me and Anna over who would inherit the mansion. \nAs the first twin to see the light, I claimed birthright\"")
		if event.is_action_pressed("Option3"):
			give_dialogue("You read of a race called the Dohwar, who were three foot avians\n not unlike penguins. It seems fictional...")
			
func drop_books():
	if books_dropped:
		return
		
	print_debug("Dropping books from bookshelf_2")
	books_dropped = true
	
	# First make the falling books visible and interactive
	make_book_interactive(annas)
	make_book_interactive(vlads)
	make_book_interactive(nanas)
	
	# Wait a longer time for the books to fall (increased from 1.0 to 3.0)
	await get_tree().create_timer(3.0).timeout
	
	# Completely disable the falling books to prevent pickup issues
	if annas:
		annas.visible = false
		annas.remove_from_group("item")
		if annas is RigidBody2D:
			annas.set_process(false)
			annas.set_physics_process(false)
			annas.sleeping = true
		var collision = annas.get_node_or_null("CollisionShape2D")
		if collision:
			collision.disabled = true
		print_debug("Disabled falling Anna book completely")
		
	if vlads:
		vlads.visible = false
		vlads.remove_from_group("item")
		if vlads is RigidBody2D:
			vlads.set_process(false)
			vlads.set_physics_process(false)
			vlads.sleeping = true
		var collision = vlads.get_node_or_null("CollisionShape2D")
		if collision:
			collision.disabled = true
		print_debug("Disabled falling Vlad book completely")
		
	if nanas:
		nanas.visible = false
		nanas.remove_from_group("item")
		if nanas is RigidBody2D:
			nanas.set_process(false)
			nanas.set_physics_process(false)
			nanas.sleeping = true
		var collision = nanas.get_node_or_null("CollisionShape2D")
		if collision:
			collision.disabled = true
		print_debug("Disabled falling Nana book completely")
	
	# Show the interactive book sprites
	annas_book.visible = true
	vlads_book.visible = true
	nanas_book.visible = true
	
	# Set locations for the books to match where the falling books landed
	if annas and annas_book:
		annas_book.position = annas.position
		print_debug("Set Anna book position to: ", annas_book.position)
		
	if vlads and vlads_book:
		vlads_book.position = vlads.position
		print_debug("Set Vlad book position to: ", vlads_book.position)
		
	if nanas and nanas_book:
		nanas_book.position = nanas.position
		print_debug("Set Nana book position to: ", nanas_book.position)
	
	# Make sure the book content is set directly
	if annas_book:
		annas_book.set_meta("book_content", book_contents["Anna_Autobiography"])
		print_debug("Set Anna book content directly")
		
	if vlads_book:
		vlads_book.set_meta("book_content", book_contents["Vlad_Autobiography"])
		print_debug("Set Vlad book content directly")
		
	if nanas_book:
		nanas_book.set_meta("book_content", book_contents["Nana_Autobiography"])
		print_debug("Set Nana book content directly")
	
	# Ensure books are properly set up for interaction
	setup_autobiography_book(annas_book, "Anna")
	setup_autobiography_book(vlads_book, "Vlad")
	setup_autobiography_book(nanas_book, "Nana")
	
	print_debug("Books dropped and made interactive")
	
	# Reset dialogue state to allow future interactions
	dialogue_active = false
	
# Helper function to ensure autobiography books are properly setup
func setup_autobiography_book(book, name_prefix):
	if book:
		# Make sure it's in the item group
		if not book.is_in_group("item"):
			book.add_to_group("item")
			print_debug("Added " + name_prefix + " book to item group")
		
		# Set can_be_picked_up flag
		book.can_be_picked_up = true
		
		# Enable collision
		var collision = book.get_node_or_null("CollisionShape2D")
		if collision:
			collision.disabled = false
		
		# Make sure monitoring is enabled for Area2D
		if book is Area2D:
			book.monitoring = true
			book.monitorable = true
		
		print_debug(name_prefix + " book properly configured for pickup")

# Make a book interactive so it can be picked up
func make_book_interactive(book):
	if book:
		print_debug("Making book interactive: ", book.name)
		# Show the book
		book.show()
		
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
			print_debug("Applied physics to book: ", book.name)
			
		# If it's an Area2D (item.gd), enable collision
		elif book is Area2D:
			var collision = book.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = false
				print_debug("Enabled collision for book: ", book.name)
	else:
		push_warning("Attempted to make null book interactive in bookshelf_2")
