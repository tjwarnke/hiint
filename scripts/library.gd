extends Node2D

var player_in_1 = false # tracks if player is close enough to interact with lectern 1
var player_in_2 = false
var player_in_3 = false

var lec1 = false # Tracks the state of the lectern1
var lec2 = false
var lec3 = false

var dialogue_active = false
var text_box = null
var dialogue = null

var book_on_lectern1 = null # Holds the reference to the book on lectern 1
var book_on_lectern2 = null
var book_on_lectern3 = null

var player

var is_placing_book = false # Flag to track when a book is being placed by the library

@onready var lecturn1 = $Lec1/Lectern1
@onready var lecturn2 = $Lec2/Lectern2
@onready var lecturn3 = $Lec3/Lectern3

func _ready():
	# Find collision areas for each lectern if they exist
	for i in range(3):
		var lectern = get_node_or_null("Lec%d/Lectern%d" % [i+1, i+1])
		if lectern:
			# Check if the collision area exists under various possible names
			var collision_area = lectern.get_node_or_null("CollisionShape2D") 
			if not collision_area:
				var area = lectern.get_node_or_null("Area2D")
	
	# Make sure we connect signals to the lecterns themselves as well
	if lecturn1:
		lecturn1.body_entered.connect(_on_lectern_1_body_entered)
		lecturn1.body_exited.connect(_on_lectern_1_body_exited)
	if lecturn2:
		lecturn2.body_entered.connect(_on_lectern_2_body_entered)
		lecturn2.body_exited.connect(_on_lectern_2_body_exited)
	if lecturn3:
		lecturn3.body_entered.connect(_on_lectern_3_body_entered)
		lecturn3.body_exited.connect(_on_lectern_3_body_exited)
	
	player = get_node_or_null("/root/World/Player")
	text_box = get_node_or_null("../UI/TextBoxMiddleTop")
	dialogue = get_node_or_null("../UI/DialogOptions")
	
	# Make sure all books start invisible
	var world = get_node_or_null("/root/World")
	if world:
		for child in world.get_children():
			if child.name.contains("Autobiography"):
				child.visible = false
				child.monitoring = false
				child.monitorable = false
				child.can_be_picked_up = false
				# Disable collision shapes
				for shape in child.get_children():
					if shape is CollisionShape2D or shape is CollisionPolygon2D:
						shape.disabled = true
	
	if not text_box:
		push_warning("TextBoxMiddleTop not found in scene")
	if not dialogue:
		push_warning("DialogOptions not found in scene")

# Called every frame to update lectern tooltips
func _process(_delta):
	update_lectern_tooltips()

# Update tooltips for lecterns
func update_lectern_tooltips():
	if !player:
		player = get_node_or_null("/root/World/Player")
		return
	
	# Check if player has items in inventory
	if player and player.has_method("has_items") and player.has_items():
		if player_in_1 and not dialogue_active:
			show_set_down_tooltip()
		elif player_in_2 and not dialogue_active:
			show_set_down_tooltip()
		elif player_in_3 and not dialogue_active:
			show_set_down_tooltip()
	
# Show tooltip for setting down items
func show_set_down_tooltip():
	if text_box and not text_box.visible:
		# Get the current key binding for set_down action
		var key = "Q"  # Default fallback
		if InputMap.has_action("set_down") and InputMap.action_get_events("set_down").size() > 0:
			key = InputMap.action_get_events("set_down")[0].as_text()
			# Remove the "(physical)" part if present
			if "(" in key:
				key = key.split("(")[0].strip_edges()
		
		text_box.visible = true
		text_box.text = "Press '%s' to set down" % key
	
func _input(event):
	if !player:
		player = get_node("/root/World/Player")
		if !player:
			return
	
	# Direct hotkey handler for book switching when near lecterns
	if (player_in_1 || player_in_2 || player_in_3):
		if event.is_action_pressed("number_1") || event.is_action_pressed("number_2") || event.is_action_pressed("number_3"):
			# Get all books in scene
			var all_books = []
			var world = get_node_or_null("/root/World")
			if world:
				for child in world.get_children():
					if child.name.contains("Book") || child.name.contains("Autobiography"):
						all_books.append(child)
				
				# Try to find Anna's book specifically
				var anna_book = null
				for book in all_books:
					if book.name.contains("Anna"):
						anna_book = book
						break
				
				# If we found Anna's book and it's not on a lectern, force player to pick it up
				if anna_book && anna_book != book_on_lectern1 && anna_book != book_on_lectern2 && anna_book != book_on_lectern3:
					# Make sure the book is visible and pickable
					anna_book.visible = true
					
					# Reset physics properties for pickup
					if anna_book is RigidBody2D:
						anna_book.freeze = false
						anna_book.sleeping = false
						anna_book.gravity_scale = 0.5
						anna_book.collision_layer = 1
						anna_book.collision_mask = 1
						anna_book.linear_velocity = Vector2.ZERO
						anna_book.angular_velocity = 0
						
						# Enable any collision shapes
						for shape in anna_book.get_children():
							if shape is CollisionShape2D or shape is CollisionPolygon2D:
								shape.disabled = false
					
					# If the book has Area2D functionality
					if anna_book is Area2D:
						anna_book.monitoring = true
						anna_book.monitorable = true
						
						# Enable collision shapes
						for shape in anna_book.get_children():
							if shape is CollisionShape2D or shape is CollisionPolygon2D:
								shape.disabled = false
					
					# Add to item group if not already there
					if not anna_book.is_in_group("item"):
						anna_book.add_to_group("item")
					
					# Set special flag if available
					if "can_be_picked_up" in anna_book:
						anna_book.can_be_picked_up = true
						
					# Force to player's position so they can pick it up
					if player:
						anna_book.global_position = player.global_position + Vector2(50, -50)
					
					# Try to pick up the book
					player.pick_up_item(anna_book)
					return
	
	# Handle setting down books with 'q' key
	if event.is_action_pressed("set_down") and player and player.has_method("has_items") and player.has_items():
		var current_item = player.held_items[player.selected_item_index] if not player.held_items.is_empty() else null
			
		if current_item and (current_item.name.contains("Vlad") or current_item.name.contains("Anna") or current_item.name.contains("Nana") or current_item.name.contains("Autobiography") or current_item.name.contains("Book") or current_item.is_in_group("books")):
			if player_in_1:
				place_book_on_lectern(current_item, 1)
				get_viewport().set_input_as_handled() # Stop event propagation to prevent player's drop_item from being called
				return
			elif player_in_2:
				place_book_on_lectern(current_item, 2)
				get_viewport().set_input_as_handled() # Stop event propagation to prevent player's drop_item from being called
				return
			elif player_in_3:
				place_book_on_lectern(current_item, 3)
				get_viewport().set_input_as_handled() # Stop event propagation to prevent player's drop_item from being called
				return
	
	# Keep existing pick_up logic for taking books from lecterns
	if event.is_action_pressed("pick_up"):
		# ... existing code ...

func lectern(event, number):
	print("=== BOOK REMOVAL STARTED ===")
	print("Attempting to take book from lectern ", number)
	if number == 1 and book_on_lectern1:
		text_box.text = "You take the book from the lectern"
		# Remove from lectern first
		var book = book_on_lectern1
		book_on_lectern1 = null
		lec1 = false
		print("Book ", book.name, " removed from lectern 1")
		print("Book position before pickup: ", book.global_position)
		# Then pick up the book
		player.call_deferred("pick_up", book)
	elif number == 2 and book_on_lectern2:
		text_box.text = "You take the book from the lectern"
		var book = book_on_lectern2
		book_on_lectern2 = null
		lec2 = false
		print("Book ", book.name, " removed from lectern 2")
		print("Book position before pickup: ", book.global_position)
		player.call_deferred("pick_up", book)
	elif number == 3 and book_on_lectern3:
		text_box.text = "You take the book from the lectern"
		var book = book_on_lectern3
		book_on_lectern3 = null
		lec3 = false
		print("Book ", book.name, " removed from lectern 3")
		print("Book position before pickup: ", book.global_position)
		player.call_deferred("pick_up", book)
		
	check_puzzle()
	print("=== BOOK REMOVAL COMPLETED ===\n")

func check_puzzle():
	print("\n[BOOK PUZZLE] Current book placements:")
	print("Lectern 1: ", book_on_lectern1.name if book_on_lectern1 else "None")
	print("Lectern 2: ", book_on_lectern2.name if book_on_lectern2 else "None")
	print("Lectern 3: ", book_on_lectern3.name if book_on_lectern3 else "None")
	
	# Check if all lecterns have books
	var puzzle_complete = true
	
	if not book_on_lectern1 or not book_on_lectern2 or not book_on_lectern3:
		print("[BOOK PUZZLE] Puzzle incomplete: Not all lecterns have books")
		puzzle_complete = false
		return
	
	# Check book positions, status, and other properties
	print("\n[BOOK PUZZLE] Book status:")
	
	if book_on_lectern1:
		print("Book 1 (", book_on_lectern1.name, "):")
		print("  - Position: ", book_on_lectern1.global_position)
		print("  - Parent: ", book_on_lectern1.get_parent().name if book_on_lectern1.get_parent() else "None")
		print("  - Visible: ", book_on_lectern1.visible)
	
	if book_on_lectern2:
		print("Book 2 (", book_on_lectern2.name, "):")
		print("  - Position: ", book_on_lectern2.global_position)
		print("  - Parent: ", book_on_lectern2.get_parent().name if book_on_lectern2.get_parent() else "None")
		print("  - Visible: ", book_on_lectern2.visible)
	
	if book_on_lectern3:
		print("Book 3 (", book_on_lectern3.name, "):")
		print("  - Position: ", book_on_lectern3.global_position)
		print("  - Parent: ", book_on_lectern3.get_parent().name if book_on_lectern3.get_parent() else "None")
		print("  - Visible: ", book_on_lectern3.visible)
		
	# Check for the correct arrangement of books
	print("\n[BOOK PUZZLE] Book arrangement check:")
	var correct_arrangement = true
	
	# Print detailed info about expected book arrangement
	print("Expected arrangement:")
	print("  - Lectern 1 should have: Book with 'Vlad' in the name")
	print("  - Lectern 2 should have: Book with 'Anna' in the name")
	print("  - Lectern 3 should have: Book with 'Nana' in the name")
	
	print("\nActual arrangement:")
	print("  - Lectern 1 has: ", book_on_lectern1.name if book_on_lectern1 else "None")
	print("  - Lectern 2 has: ", book_on_lectern2.name if book_on_lectern2 else "None")
	print("  - Lectern 3 has: ", book_on_lectern3.name if book_on_lectern3 else "None")
	
	# Check each lectern for the expected book
	if book_on_lectern1:
		if book_on_lectern1.name.contains("Vlad"):
			print("✓ Lectern 1 has correct book: ", book_on_lectern1.name)
		else:
			print("✗ Lectern 1 has INCORRECT book. Expected 'Vlad', got: ", book_on_lectern1.name)
			correct_arrangement = false
	
	if book_on_lectern2:
		if book_on_lectern2.name.contains("Anna"):
			print("✓ Lectern 2 has correct book: ", book_on_lectern2.name)
		else:
			print("✗ Lectern 2 has INCORRECT book. Expected 'Anna', got: ", book_on_lectern2.name)
			correct_arrangement = false
	
	if book_on_lectern3:
		if book_on_lectern3.name.contains("Nana"):
			print("✓ Lectern 3 has correct book: ", book_on_lectern3.name)
		else:
			print("✗ Lectern 3 has INCORRECT book. Expected 'Nana', got: ", book_on_lectern3.name)
			correct_arrangement = false
	
	puzzle_complete = correct_arrangement
	
	print("\n[BOOK PUZZLE] Puzzle complete? ", puzzle_complete)
	
	if puzzle_complete:
		print("Puzzle complete! All books in correct positions")
		print("Beginning door opening sequence...")
		
		# Disable the main camera
		var main_camera = get_node("/root/World/Camera2D")
		if main_camera:
			main_camera.enabled = false
			print("Main camera disabled")
		else:
			print("WARNING: Main camera not found")
		
		# Enable the library door camera
		var lib_door_camera = get_node("/root/World/LibDoor")
		if lib_door_camera:
			lib_door_camera.enabled = true
			print("Library door camera enabled")
		else:
			print("WARNING: Library door camera not found")
		
		# Open the door
		open_door()
		
		# Wait for door animation to complete
		await get_tree().create_timer(2.0).timeout
		
		# Switch cameras back
		if main_camera:
			main_camera.enabled = true
			print("Main camera re-enabled")
		if lib_door_camera:
			lib_door_camera.enabled = false
			print("Library door camera disabled")
	else:
		print("Puzzle incomplete: Books not in correct positions or missing")
	print("=== PUZZLE CHECK COMPLETED ===\n")

func open_door():
	print("=== DOOR OPENING STARTED ===")
	print("Attempting to open door")
	var billiards_room = get_node_or_null("/root/World/BilliardsRoom")
	if billiards_room:
		var anim_player = billiards_room.get_node_or_null("AnimationPlayer")
		if anim_player:
			print("Playing door open animation")
			anim_player.play("door open")
			# Show success message
			if text_box:
				text_box.visible = true
				text_box.text = "The door creaks open..."
				await get_tree().create_timer(2).timeout
				text_box.visible = false
		else:
			print("WARNING: AnimationPlayer not found in billiards room scene")
	else:
		print("WARNING: Billiards room scene not found")
	print("=== DOOR OPENING COMPLETED ===\n")

func place_book_on_lectern(book, lectern_number):
	print("\n[BOOK PUZZLE] Placing book: ", book.name, " on lectern: ", lectern_number)
	print("[BOOK PUZZLE] Book position before placement: ", book.global_position)
	print("[BOOK PUZZLE] Book parent: ", book.get_parent().name if book.get_parent() else "None")
	
	# First check if this lectern already has a book
	if (lectern_number == 1 and book_on_lectern1 != null) or \
	   (lectern_number == 2 and book_on_lectern2 != null) or \
	   (lectern_number == 3 and book_on_lectern3 != null):
		print("[BOOK PUZZLE] Lectern already has a book on it")
		if text_box:
			text_box.visible = true
			text_box.text = "There's already a book on this lectern"
			await get_tree().create_timer(2).timeout
			text_box.visible = false
		is_placing_book = false
		return
	
	# Get the lectern and target position
	var lectern = null
	var target_position = Vector2.ZERO
	
	# Store the book for later reference in the puzzle logic
	match lectern_number:
		1:
			lectern = lecturn1
			book_on_lectern1 = book
			lec1 = true
			target_position = Vector2(1627.0, -1527.0)  # Exact position for lectern 1
		2:
			lectern = lecturn2
			book_on_lectern2 = book
			lec2 = true
			target_position = Vector2(2073.0, -1536.0)  # Exact position for lectern 2
		3:
			lectern = lecturn3
			book_on_lectern3 = book
			lec3 = true
			target_position = Vector2(2525.0, -1520.0)  # Exact position for lectern 3
	
	if lectern:
		print("Lectern found, proceeding with book placement")
		print("Lectern position: ", lectern.global_position)
		print("Lectern children: ", lectern.get_children())
		
		# Store a reference to the book before dropping
		var book_ref = book
		
		# Remove the item from the player's inventory
		player.drop_item(false)
		print("Book dropped from player inventory")
		
		# Wait for the next frame to ensure the book is properly dropped
		await get_tree().process_frame
		await get_tree().process_frame  # Wait an extra frame for safety
		
		# Get the world node
		var world = get_node_or_null("/root/World")
		if not world:
			return
		
		# Check if the book is valid after dropping
		if not is_instance_valid(book_ref):
			return
		
		# Check if the book is already in the World node
		if book_ref.get_parent() == world:
			print("Book already parented to world, skipping reparenting")
		elif book_ref.get_parent() != null:
			book_ref.get_parent().remove_child(book_ref)
			world.add_child(book_ref)
		else:
			world.add_child(book_ref)
		
		# IMPORTANT: First attempt - set the book's position
		print("Book position before setting: ", book_ref.global_position)
		book_ref.global_position = target_position
		book_ref.rotation = 0
		book_ref.visible = true
		print("Book position after first setting: ", book_ref.global_position, " (Target was: ", target_position, ")")
		
		# Second attempt - use global_transform to better ensure position is set
		book_ref.global_transform.origin = target_position
		print("Book position after global_transform update: ", book_ref.global_position)
		
		# Third attempt - if there's still a discrepancy, use a deferred call
		if book_ref.global_position.distance_to(target_position) > 2.0:
			print("Position discrepancy detected, using deferred call...")
			call_deferred("force_book_position", book_ref, target_position)
		
		# Set physics properties for RigidBody2D
		if book_ref is RigidBody2D:
			print("Book is RigidBody2D, setting physics properties...")
			
			# Store original physics properties for debugging
			print("Original physics properties:")
			print("  - gravity_scale: ", book_ref.gravity_scale)
			print("  - freeze: ", book_ref.freeze)
			print("  - sleeping: ", book_ref.sleeping)
			print("  - collision_layer: ", book_ref.collision_layer)
			print("  - collision_mask: ", book_ref.collision_mask)
			
			# Explicitly set each property to ensure the book stays in place
			book_ref.freeze = true
			book_ref.sleeping = true
			book_ref.gravity_scale = 0
			book_ref.collision_layer = 2  # Use a different layer than player
			book_ref.collision_mask = 0   # Don't collide with anything
			book_ref.contact_monitor = true
			book_ref.max_contacts_reported = 1
			book_ref.linear_velocity = Vector2.ZERO
			book_ref.angular_velocity = 0
			
			# Ensure the book is visible
			book_ref.visible = true
			
			print("New physics properties:")
			print("  - gravity_scale: ", book_ref.gravity_scale)
			print("  - freeze: ", book_ref.freeze)
			print("  - sleeping: ", book_ref.sleeping)
			print("  - collision_layer: ", book_ref.collision_layer)
			print("  - collision_mask: ", book_ref.collision_mask)
			print("  - contact_monitor: ", book_ref.contact_monitor)
			print("  - max_contacts_reported: ", book_ref.max_contacts_reported)
			print("  - linear_velocity: ", book_ref.linear_velocity)
			print("  - angular_velocity: ", book_ref.angular_velocity)
			
		# Final position verification
		print("Final book position verification: ", book_ref.global_position)
		print("Distance from target: ", book_ref.global_position.distance_to(target_position))
		# Force position one more time
		book_ref.global_position = target_position
		
		# Show feedback message
		if text_box:
			text_box.visible = true
			text_box.text = "You place the book on the lectern"
			await get_tree().create_timer(2).timeout
			text_box.visible = false
		
		# Debug book references to ensure they're correctly set
		print("\nBOOK REFERENCES VERIFICATION:")
		print("Book on Lectern 1: ", book_on_lectern1.name if book_on_lectern1 else "None")
		print("Book on Lectern 2: ", book_on_lectern2.name if book_on_lectern2 else "None")
		print("Book on Lectern 3: ", book_on_lectern3.name if book_on_lectern3 else "None")
		
		# Create a timer to check the book's position a bit later to make sure it stays in place
		get_tree().create_timer(0.5).timeout.connect(func(): verify_book_position(book_ref, target_position, lectern_number))
		
		# Check if puzzle is complete
		call_deferred("check_puzzle")
	else:
		print("ERROR: Lectern not found for lectern ", lectern_number)
	
	print("=== BOOK PLACEMENT COMPLETED ===\n")
	is_placing_book = false # Clear the flag when done

# Helper function to force book position on deferred call
func force_book_position(book, position):
	if book and is_instance_valid(book):
		print("\n[FORCE-POSITION] Forcing book position for: ", book.name)
		print("[FORCE-POSITION] Current position: ", book.global_position)
		print("[FORCE-POSITION] Target position: ", position)
		
		book.global_position = position
		book.global_transform.origin = position
		
		if book is RigidBody2D:
			book.freeze = true
			book.sleeping = true
		
		print("[FORCE-POSITION] New position: ", book.global_position)
		print("[FORCE-POSITION] Distance from target: ", book.global_position.distance_to(position))

# Helper function to verify book position after a delay
func verify_book_position(book, expected_position, lectern_number):
	if is_placing_book:
		return
		
	if book and is_instance_valid(book):
		var distance = book.global_position.distance_to(expected_position)
		
		if distance > 5.0:
			book.global_position = expected_position
			
			# Make sure the book is correctly referenced
			match lectern_number:
				1:
					if book_on_lectern1 != book:
						book_on_lectern1 = book
				2:
					if book_on_lectern2 != book:
						book_on_lectern2 = book
				3:
					if book_on_lectern3 != book:
						book_on_lectern3 = book
			
			# Check if the physics properties are still correct
			if book is RigidBody2D:
				if not book.freeze or not book.sleeping:
					book.freeze = true
					book.sleeping = true
					book.gravity_scale = 0
					book.collision_layer = 2
					book.collision_mask = 0
		else:
			print("[VERIFY] Book position is stable")
		
		# Call check_puzzle again to make sure the puzzle state is updated
		call_deferred("check_puzzle")

func _on_lectern_1_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_1 = true
		player = body

func _on_lectern_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_2 = true
		player = body

func _on_lectern_3_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_3 = true
		player = body

func _on_lectern_1_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_1 = false
		if text_box and text_box.visible and text_box.text.begins_with("Press"):
			text_box.visible = false
		if dialogue and dialogue.visible:
			dialogue.visible = false

func _on_lectern_2_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_2 = false
		if text_box and text_box.visible and text_box.text.begins_with("Press"):
			text_box.visible = false
		if dialogue and dialogue.visible:
			dialogue.visible = false

func _on_lectern_3_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_3 = false
		if text_box and text_box.visible and text_box.text.begins_with("Press"):
			text_box.visible = false
		if dialogue and dialogue.visible:
			dialogue.visible = false
