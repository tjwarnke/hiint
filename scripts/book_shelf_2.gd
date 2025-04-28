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

func find_node_by_name(root: Node, name: String) -> Node:
	if root.name == name:
		return root
	for child in root.get_children():
		var found = find_node_by_name(child, name)
		if found:
			return found
	return null

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	# Try to find UI elements in the scene tree
	text_box = get_node_or_null("../../UI/TextBoxMiddleTop")
	dialogue = get_node_or_null("../../UI/DialogOptions")
	
	if not text_box:
		push_warning("TextBoxMiddleTop not found in scene")
	if not dialogue:
		push_warning("DialogOptions not found in scene")
	
	# Initialize rigid bodies
	var library = get_node_or_null("/root/World/Library")
	if library:
		# Search for rigid bodies in the Library scene
		annas = library.get_node_or_null("Anna")
		vlads = library.get_node_or_null("Vlad")
		nanas = library.get_node_or_null("Nana")
		
		# Initially disable and hide the rigid bodies
		if annas:
			annas.freeze = true
			annas.visible = false
			annas.can_be_picked_up = false
		if vlads:
			vlads.freeze = true
			vlads.visible = false
			vlads.can_be_picked_up = false
		if nanas:
			nanas.freeze = true
			nanas.visible = false
			nanas.can_be_picked_up = false
	else:
		push_warning("Library node not found")

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
	await get_tree().create_timer(10.0).timeout
	text_box.visible = false
	dialogue_active = false

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		
		text_box.text = "It looks like some books have been taken off the shelf recently"
		text_box.visible = true
		
		var timer = get_tree().create_timer(2.0)
		await timer.timeout
		
		if player_nearby:
			text_box.text = "Would you like to read any? Read:"
			
			timer = get_tree().create_timer(1.0)
			await timer.timeout
			
			if player_nearby:
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
			give_dialogue("You read of a race called the Dohwar, who were three foot avians\n not unlike penguins. It seems fictional...")

func drop_books():
	if not books_dropped:
		books_dropped = true
		var books = []
		
		# First try to find books in the library scene
		var library = get_node_or_null("/root/World/Library")
		if library:
			for child in library.get_children():
				if child.name.contains("Autobiography"):
					books.append(child)
		
		# If no books found in library, try the world scene
		if books.is_empty():
			var world = get_node_or_null("/root/World")
			if world:
				for child in world.get_children():
					if child.name.contains("Autobiography"):
						books.append(child)
		
		# Make the books fall
		for book in books:
			if book is RigidBody2D:
				# Enable physics properties
				book.freeze = false
				book.gravity_scale = 1.0
				book.visible = true
				book.can_be_picked_up = true
				
				# Enable collision shapes
				for shape in book.get_children():
					if shape is CollisionShape2D or shape is CollisionPolygon2D:
						shape.disabled = false
				
				# Apply a small random impulse to make books fall differently
				var random_impulse = Vector2(randf_range(-100, 100), randf_range(-50, 0))
				book.apply_impulse(random_impulse)
		
		# Enable and show the rigid bodies
		if annas:
			annas.freeze = false
			annas.visible = true
			annas.can_be_picked_up = true
		if vlads:
			vlads.freeze = false
			vlads.visible = true
			vlads.can_be_picked_up = true
		if nanas:
			nanas.freeze = false
			nanas.visible = true
			nanas.can_be_picked_up = true
