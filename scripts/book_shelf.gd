extends Sprite2D

signal book_placed
signal book_removed

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var book_taken = false
var current_book = null
var debug_timer = 2.0  # Timer for debug output

# UI elements - will be set in _ready
var text_box = null
var dialogue = null
var book = null

# For lectern functionality
var is_lectern = false
var lectern_area = null

func _ready():
	# Player detection
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	print("[DEBUG] Node name: ", name, " Path: ", get_path())
	print("[DEBUG] Children: ", get_children())
	
	# Check if this is a lectern - check for LecternArea among all children recursively
	is_lectern = name.contains("Lectern")
	if is_lectern:
		print("[DEBUG] This is a lectern: ", name)
		
		# Try to find the LecternArea node as a direct child
		lectern_area = get_node_or_null("LecternArea")
		
		# If not found, try to find it among child nodes recursively
		if not lectern_area:
			for child in get_children():
				if child.name == "LecternArea":
					lectern_area = child
					break
				# Try one level deeper
				for grandchild in child.get_children():
					if grandchild.name == "LecternArea":
						lectern_area = grandchild
						break
		
		if lectern_area:
			print("[DEBUG] Found LecternArea for lectern: ", name)
			lectern_area.area_entered.connect(_on_lectern_area_entered)
			lectern_area.area_exited.connect(_on_lectern_area_exited)
		else:
			print("[DEBUG] LecternArea node not found for: ", name)
	
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

func _on_lectern_area_entered(area):
	print("[DEBUG] Area entered lectern: ", area.name, " Parent: ", area.get_parent().name if area.get_parent() else "None")
	if area.is_in_group("books"):
		print("[DEBUG] Book entered lectern: ", area.name)
		print("[DEBUG] Current book on lectern: ", current_book)
		
		# Debug the area's parent to make sure we're getting the book itself
		var parent = area.get_parent()
		print("[DEBUG] Area's parent: ", parent.name if parent else "None")
		print("[DEBUG] Area's parent groups: ", parent.get_groups() if parent else "None")
		
		# If parent is a RigidBody2D, it's probably the book we want
		var book_node = null
		if parent and parent is RigidBody2D:
			book_node = parent
		# If the area itself is a RigidBody2D, use that
		elif area is RigidBody2D:
			book_node = area
		# Otherwise use whatever we have
		else:
			book_node = area
		
		if current_book == null:
			print("[DEBUG] No book currently on lectern, accepting: ", book_node.name)
			current_book = book_node
			
			# Make sure the book stays in position
			if current_book is RigidBody2D:
				current_book.freeze = true
				current_book.sleeping = true
				current_book.collision_layer = 0  # Prevent collision with player
				current_book.collision_mask = 0
				print("[DEBUG] Set book physics state for lectern placement:")
				print("  - gravity_scale: ", current_book.gravity_scale)
				print("  - freeze: ", current_book.freeze)
				print("  - sleeping: ", current_book.sleeping)
				print("  - collision_layer: ", current_book.collision_layer)
				print("  - collision_mask: ", current_book.collision_mask)
			
			# Connect to tree_exiting signal for cleanup
			if not current_book.is_connected("tree_exiting", Callable(self, "_on_book_removed")):
				current_book.connect("tree_exiting", Callable(self, "_on_book_removed"))
			
			emit_signal("book_placed", current_book)
		else:
			print("[DEBUG] Lectern already has a book: ", current_book.name)

func _on_lectern_area_exited(area):
	print("[DEBUG] Area exited lectern: ", area.name)
	
	# Check if the exiting area is a book or belongs to a book
	var exiting_book = null
	if area.is_in_group("books"):
		exiting_book = area
		var parent = area.get_parent()
		if parent and parent is RigidBody2D:
			exiting_book = parent
	
	# We need to compare against the current_book or its Area2D
	var matches_current = false
	if current_book:
		if exiting_book == current_book:
			matches_current = true
		# Check if the exiting area belongs to our current book
		elif current_book.has_node("Area2D") and current_book.get_node("Area2D") == area:
			matches_current = true
		# Check if our current book is the parent of this area
		elif area.get_parent() == current_book:
			matches_current = true
	
	# Check if this is our current book
	if exiting_book and matches_current:
		print("[DEBUG] Book removed from lectern: ", exiting_book.name)
		
		# Restore physics properties
		if exiting_book is RigidBody2D:
			exiting_book.freeze = false
			exiting_book.sleeping = false
			exiting_book.gravity_scale = 1.0
			exiting_book.collision_layer = 1
			exiting_book.collision_mask = 1
			print("[DEBUG] Restored book physics for: ", exiting_book.name)
			print("  - gravity_scale: ", exiting_book.gravity_scale)
			print("  - freeze: ", exiting_book.freeze)
			print("  - sleeping: ", exiting_book.sleeping)
			print("  - collision_layer: ", exiting_book.collision_layer)
			print("  - collision_mask: ", exiting_book.collision_mask)
		
		# Disconnect the signal
		if exiting_book.is_connected("tree_exiting", Callable(self, "_on_book_removed")):
			exiting_book.disconnect("tree_exiting", Callable(self, "_on_book_removed"))
		
		current_book = null
		emit_signal("book_removed", exiting_book)

func _on_book_removed():
	print("[DEBUG] Book was removed from scene while on lectern")
	current_book = null

func _process(delta):
	# Debug monitoring for books and lectern - only update every 2 seconds
	if current_book:
		debug_timer += delta
		if debug_timer >= 2.0:
			debug_timer = 0.0
			
			print("[DEBUG-LECTERN] Book on lectern: ", current_book.name)
			print("[DEBUG-LECTERN] Book position: ", current_book.global_position)
			print("[DEBUG-LECTERN] Lectern position: ", global_position)
			
			# Check for any books that might be colliding - but use a safer approach
			var space_state = get_world_2d().direct_space_state
			
			# Create a physics point query at the book's position
			var query = PhysicsPointQueryParameters2D.new()
			query.position = current_book.global_position
			query.collision_mask = 1  # Default collision mask
			
			var results = space_state.intersect_point(query)
			if results.size() > 1:  # More than just the book itself
				print("[DEBUG-LECTERN] Book is colliding with other objects at its position")
				for result in results:
					var collider = result["collider"]
					if collider != current_book:
						print("  - Colliding with: ", collider.name if collider else "Unknown")
