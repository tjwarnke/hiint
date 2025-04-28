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

@onready var lecturn1 = $Lec1/Lectern1
@onready var lecturn2 = $Lec2/Lectern2
@onready var lecturn3 = $Lec3/Lectern3

func _ready():
	# Print debug information about the lectern hierarchy
	print("[DEBUG] Library scene structure:")
	print("  - Lectern1 path: ", lecturn1.get_path() if lecturn1 else "Not found")
	print("  - Lectern2 path: ", lecturn2.get_path() if lecturn2 else "Not found")
	print("  - Lectern3 path: ", lecturn3.get_path() if lecturn3 else "Not found")
	
	# Find collision areas for each lectern if they exist
	for i in range(3):
		var lectern = get_node_or_null("Lec%d/Lectern%d" % [i+1, i+1])
		if lectern:
			print("  - Lectern%d children: " % [i+1], lectern.get_children())
			
			# Check if the collision area exists under various possible names
			var collision_area = lectern.get_node_or_null("CollisionShape2D") 
			if collision_area:
				print("    - CollisionShape2D found for Lectern%d" % [i+1])
			else:
				var area = lectern.get_node_or_null("Area2D")
				if area:
					print("    - Area2D found for Lectern%d" % [i+1])
				else:
					print("    - No collision shape found for Lectern%d" % [i+1])
	
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
			print("[INPUT] Player not found!")
			return
	
	print("\n[INPUT] Processing input event: ", event.as_text())
	
	# Direct hotkey handler for book switching when near lecterns
	if (player_in_1 || player_in_2 || player_in_3):
		if event.is_action_pressed("number_1") || event.is_action_pressed("number_2") || event.is_action_pressed("number_3"):
			print("[LIBRARY] Direct number key press detected near lectern")
			# Get all books in scene
			var all_books = []
			var world = get_node_or_null("/root/World")
			if world:
				for child in world.get_children():
					if child.name.contains("Book") || child.name.contains("Autobiography"):
						print("[LIBRARY] Found book: ", child.name)
						all_books.append(child)
				
				# Try to find Anna's book specifically
				var anna_book = null
				for book in all_books:
					if book.name.contains("Anna"):
						anna_book = book
						print("[LIBRARY] Found Anna's book: ", anna_book.name)
						break
				
				# If we found Anna's book and it's not on a lectern, force player to pick it up
				if anna_book && anna_book != book_on_lectern1 && anna_book != book_on_lectern2 && anna_book != book_on_lectern3:
					print("[LIBRARY] Forcing pickup of Anna's book")
					
					# Make sure the book is visible and pickable
					anna_book.visible = true
					
					# Reset physics properties for pickup
					if anna_book is RigidBody2D:
						print("[LIBRARY] Resetting physics properties for Anna's book")
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
		print("[INPUT] 'set_down' action detected. Player has items: ", player.has_items())
		
		var current_item = player.held_items[player.selected_item_index] if not player.held_items.is_empty() else null
		if current_item:
			print("[INPUT] Current selected item: ", current_item.name)
			print("[INPUT] Item class: ", current_item.get_class())
			print("[INPUT] Is book? ", (current_item.name.contains("Vlad") or current_item.name.contains("Anna") or current_item.name.contains("Nana") or current_item.is_in_group("books")))
		else:
			print("[INPUT] No item currently selected")
			
		if current_item and (current_item.name.contains("Vlad") or current_item.name.contains("Anna") or current_item.name.contains("Nana") or current_item.name.contains("Autobiography") or current_item.name.contains("Book") or current_item.is_in_group("books")):
			print("[INPUT] Book detected for placement")
			
			# Debug player position relative to lecterns
			print("[INPUT] Player position: ", player.global_position)
			print("[INPUT] Player in lectern areas: Lec1=", player_in_1, " Lec2=", player_in_2, " Lec3=", player_in_3)
			
			# Check lectern positions
			if lecturn1:
				print("[INPUT] Lectern1 position: ", lecturn1.global_position)
				print("[INPUT] Distance to Lectern1: ", player.global_position.distance_to(lecturn1.global_position))
			if lecturn2:
				print("[INPUT] Lectern2 position: ", lecturn2.global_position)
				print("[INPUT] Distance to Lectern2: ", player.global_position.distance_to(lecturn2.global_position))
			if lecturn3:
				print("[INPUT] Lectern3 position: ", lecturn3.global_position)
				print("[INPUT] Distance to Lectern3: ", player.global_position.distance_to(lecturn3.global_position))
			
			if player_in_1:
				print("[INPUT] Player near lectern 1, placing book: ", current_item.name)
				place_book_on_lectern(current_item, 1)
				get_viewport().set_input_as_handled() # Stop event propagation to prevent player's drop_item from being called
				return
			elif player_in_2:
				print("[INPUT] Player near lectern 2, placing book: ", current_item.name)
				place_book_on_lectern(current_item, 2)
				get_viewport().set_input_as_handled() # Stop event propagation to prevent player's drop_item from being called
				return
			elif player_in_3:
				print("[INPUT] Player near lectern 3, placing book: ", current_item.name)
				place_book_on_lectern(current_item, 3)
				get_viewport().set_input_as_handled() # Stop event propagation to prevent player's drop_item from being called
				return
			else:
				print("[INPUT] Player not near any lectern, can't place book")
		else:
			print("[INPUT] Current item is not a book, ignoring placement")
	
	# Keep existing pick_up logic for taking books from lecterns
	if event.is_action_pressed("pick_up"):
		print("[INPUT] 'pick_up' action detected")
		print("[INPUT] Player near lecterns: Lec1=", player_in_1, " Lec2=", player_in_2, " Lec3=", player_in_3)
		print("[INPUT] Books on lecterns: Lec1=", book_on_lectern1 != null, " Lec2=", book_on_lectern2 != null, " Lec3=", book_on_lectern3 != null)
		
		if player_in_1 and book_on_lectern1:
			print("[INPUT] Player attempting to take book from lectern 1: ", book_on_lectern1.name if book_on_lectern1 else "None")
			lectern(event, 1)
			get_viewport().set_input_as_handled() # Stop event propagation
		elif player_in_2 and book_on_lectern2:
			print("[INPUT] Player attempting to take book from lectern 2: ", book_on_lectern2.name if book_on_lectern2 else "None")
			lectern(event, 2)
			get_viewport().set_input_as_handled() # Stop event propagation
		elif player_in_3 and book_on_lectern3:
			print("[INPUT] Player attempting to take book from lectern 3: ", book_on_lectern3.name if book_on_lectern3 else "None")
			lectern(event, 3)
			get_viewport().set_input_as_handled() # Stop event propagation
		else:
			print("[INPUT] No book to pick up from lecterns")

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
	print("\n=== PUZZLE STATE CHECK ===")
	print("Current book placements:")
	print("Lectern 1: ", book_on_lectern1.name if book_on_lectern1 else "None")
	print("Lectern 2: ", book_on_lectern2.name if book_on_lectern2 else "None")
	print("Lectern 3: ", book_on_lectern3.name if book_on_lectern3 else "None")
	
	# Check if all lecterns have books
	var puzzle_complete = true
	
	if not book_on_lectern1 or not book_on_lectern2 or not book_on_lectern3:
		print("Puzzle incomplete: Not all lecterns have books")
		puzzle_complete = false
		return
	
	# Check book positions, status, and other properties
	print("\nDETAILED BOOK STATUS:")
	
	if book_on_lectern1:
		print("Book 1 (", book_on_lectern1.name, "):")
		print("  - Position: ", book_on_lectern1.global_position)
		print("  - Parent: ", book_on_lectern1.get_parent().name if book_on_lectern1.get_parent() else "None")
		print("  - Visible: ", book_on_lectern1.visible)
		if book_on_lectern1 is RigidBody2D:
			print("  - Physics properties:")
			print("    - gravity_scale: ", book_on_lectern1.gravity_scale)
			print("    - freeze: ", book_on_lectern1.freeze)
			print("    - sleeping: ", book_on_lectern1.sleeping)
			print("    - collision_layer: ", book_on_lectern1.collision_layer)
			print("    - collision_mask: ", book_on_lectern1.collision_mask)
	
	if book_on_lectern2:
		print("Book 2 (", book_on_lectern2.name, "):")
		print("  - Position: ", book_on_lectern2.global_position)
		print("  - Parent: ", book_on_lectern2.get_parent().name if book_on_lectern2.get_parent() else "None")
		print("  - Visible: ", book_on_lectern2.visible)
		if book_on_lectern2 is RigidBody2D:
			print("  - Physics properties:")
			print("    - gravity_scale: ", book_on_lectern2.gravity_scale)
			print("    - freeze: ", book_on_lectern2.freeze)
			print("    - sleeping: ", book_on_lectern2.sleeping)
			print("    - collision_layer: ", book_on_lectern2.collision_layer)
			print("    - collision_mask: ", book_on_lectern2.collision_mask)
	
	if book_on_lectern3:
		print("Book 3 (", book_on_lectern3.name, "):")
		print("  - Position: ", book_on_lectern3.global_position)
		print("  - Parent: ", book_on_lectern3.get_parent().name if book_on_lectern3.get_parent() else "None")
		print("  - Visible: ", book_on_lectern3.visible)
		if book_on_lectern3 is RigidBody2D:
			print("  - Physics properties:")
			print("    - gravity_scale: ", book_on_lectern3.gravity_scale)
			print("    - freeze: ", book_on_lectern3.freeze)
			print("    - sleeping: ", book_on_lectern3.sleeping)
			print("    - collision_layer: ", book_on_lectern3.collision_layer)
			print("    - collision_mask: ", book_on_lectern3.collision_mask)
		
	# Check for the correct arrangement of books
	print("\nBOOK ARRANGEMENT CHECK:")
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
	
	print("\nPUZZLE COMPLETE? ", puzzle_complete)
	
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
	print("\n=== BOOK PLACEMENT STARTED ===")
	print("Attempting to place book: ", book.name, " on lectern: ", lectern_number)
	print("Book position before placement: ", book.global_position)
	print("Book parent: ", book.get_parent().name if book.get_parent() else "None")
	
	# First check if this lectern already has a book
	if (lectern_number == 1 and book_on_lectern1 != null) or \
	   (lectern_number == 2 and book_on_lectern2 != null) or \
	   (lectern_number == 3 and book_on_lectern3 != null):
		print("Lectern already has a book on it")
		if text_box:
			text_box.visible = true
			text_box.text = "There's already a book on this lectern"
			await get_tree().create_timer(2).timeout
			text_box.visible = false
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
			print("Book ", book.name, " assigned to lectern 1")
			print("Lectern1 position: ", lecturn1.global_position if lecturn1 else "Not found")
		2:
			lectern = lecturn2
			book_on_lectern2 = book
			lec2 = true
			target_position = Vector2(2073.0, -1536.0)  # Exact position for lectern 2
			print("Book ", book.name, " assigned to lectern 2")
			print("Lectern2 position: ", lecturn2.global_position if lecturn2 else "Not found")
		3:
			lectern = lecturn3
			book_on_lectern3 = book
			lec3 = true
			target_position = Vector2(2525.0, -1520.0)  # Exact position for lectern 3
			print("Book ", book.name, " assigned to lectern 3")
			print("Lectern3 position: ", lecturn3.global_position if lecturn3 else "Not found")
	
	if lectern:
		print("Lectern found, proceeding with book placement")
		print("Lectern position: ", lectern.global_position)
		print("Lectern children: ", lectern.get_children())
		
		# Remove the item from the player's inventory
		player.drop_item(false)
		print("Book dropped from player inventory")
		
		# Wait for the next frame to ensure the book is properly dropped
		await get_tree().process_frame
		await get_tree().process_frame  # Wait an extra frame for safety
		
		# Get the world node
		var world = get_node_or_null("/root/World")
		if not world:
			print("ERROR: World node not found")
			return
		
		# Check if the book is already in the World node
		# and don't try to reparent if it already has World as parent
		if book.get_parent() == world:
			print("Book already parented to world, skipping reparenting")
		elif book.get_parent() != null:
			print("Book parent before reparenting: ", book.get_parent().name if book.get_parent() else "None")
			book.get_parent().remove_child(book)
			world.add_child(book)
			print("Book reparented to world, new parent: ", book.get_parent().name)
		else:
			print("Book has no parent, adding to world")
			world.add_child(book)
			print("Book added to world, new parent: ", book.get_parent().name)
		
		# IMPORTANT: First attempt - set the book's position
		print("Book position before setting: ", book.global_position)
		book.global_position = target_position
		book.rotation = 0
		book.visible = true
		print("Book position after first setting: ", book.global_position, " (Target was: ", target_position, ")")
		
		# Second attempt - use global_transform to better ensure position is set
		book.global_transform.origin = target_position
		print("Book position after global_transform update: ", book.global_position)
		
		# Third attempt - if there's still a discrepancy, use a deferred call
		if book.global_position.distance_to(target_position) > 2.0:
			print("Position discrepancy detected, using deferred call...")
			call_deferred("force_book_position", book, target_position)
		
		# Set physics properties for RigidBody2D
		if book is RigidBody2D:
			print("Book is RigidBody2D, setting physics properties...")
			
			# Store original physics properties for debugging
			print("Original physics properties:")
			print("  - gravity_scale: ", book.gravity_scale)
			print("  - freeze: ", book.freeze)
			print("  - sleeping: ", book.sleeping)
			print("  - collision_layer: ", book.collision_layer)
			print("  - collision_mask: ", book.collision_mask)
			
			# Explicitly set each property to ensure the book stays in place
			book.freeze = true
			book.sleeping = true
			book.gravity_scale = 0
			book.collision_layer = 2  # Use a different layer than player
			book.collision_mask = 0   # Don't collide with anything
			book.contact_monitor = true
			book.max_contacts_reported = 1
			book.linear_velocity = Vector2.ZERO
			book.angular_velocity = 0
			
			# Ensure the book is visible
			book.visible = true
			
			print("New physics properties:")
			print("  - gravity_scale: ", book.gravity_scale)
			print("  - freeze: ", book.freeze)
			print("  - sleeping: ", book.sleeping)
			print("  - collision_layer: ", book.collision_layer)
			print("  - collision_mask: ", book.collision_mask)
			print("  - contact_monitor: ", book.contact_monitor)
			print("  - max_contacts_reported: ", book.max_contacts_reported)
			print("  - linear_velocity: ", book.linear_velocity)
			print("  - angular_velocity: ", book.angular_velocity)
			
		# Final position verification
		print("Final book position verification: ", book.global_position)
		print("Distance from target: ", book.global_position.distance_to(target_position))
		# Force position one more time
		book.global_position = target_position
		
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
		get_tree().create_timer(0.5).timeout.connect(func(): verify_book_position(book, target_position, lectern_number))
		
		# Check if puzzle is complete
		print("Calling check_puzzle...")
		call_deferred("check_puzzle")
	else:
		print("ERROR: Lectern not found for lectern ", lectern_number)
	
	print("=== BOOK PLACEMENT COMPLETED ===\n")

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
	if book and is_instance_valid(book):
		print("\n[VERIFY] Verifying book position after delay for: ", book.name)
		print("[VERIFY] Current position: ", book.global_position)
		print("[VERIFY] Expected position: ", expected_position)
		
		var distance = book.global_position.distance_to(expected_position)
		print("[VERIFY] Distance from expected: ", distance)
		
		if distance > 5.0:
			print("[VERIFY] Book has drifted! Correcting position...")
			book.global_position = expected_position
			
			# Make sure the book is correctly referenced
			match lectern_number:
				1:
					if book_on_lectern1 != book:
						print("[VERIFY] Book reference for lectern 1 has changed! Fixing...")
						book_on_lectern1 = book
				2:
					if book_on_lectern2 != book:
						print("[VERIFY] Book reference for lectern 2 has changed! Fixing...")
						book_on_lectern2 = book
				3:
					if book_on_lectern3 != book:
						print("[VERIFY] Book reference for lectern 3 has changed! Fixing...")
						book_on_lectern3 = book
			
			# Check if the physics properties are still correct
			if book is RigidBody2D:
				if not book.freeze or not book.sleeping:
					print("[VERIFY] Physics properties have changed, resetting...")
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
	print("\n[LECTERN] Body entered Lectern 1 area: ", body.name)
	print("[LECTERN] Body position: ", body.global_position)
	print("[LECTERN] Lectern 1 position: ", lecturn1.global_position if lecturn1 else "Not found")
	
	if body.is_in_group("player"):
		print("[LECTERN] Player entered Lectern 1 area")
		player_in_1 = true
		player = body
		
		# Debug current player state
		if player.has_method("has_items") and player.has_items():
			var current_item = player.held_items[player.selected_item_index] if not player.held_items.is_empty() else null
			print("[LECTERN] Player is holding: ", current_item.name if current_item else "None")
		else:
			print("[LECTERN] Player has no items")
		
		# Debug current lectern state
		print("[LECTERN] Book on Lectern 1: ", book_on_lectern1.name if book_on_lectern1 else "None")

func _on_lectern_2_body_entered(body: Node2D) -> void:
	print("\n[LECTERN] Body entered Lectern 2 area: ", body.name)
	print("[LECTERN] Body position: ", body.global_position)
	print("[LECTERN] Lectern 2 position: ", lecturn2.global_position if lecturn2 else "Not found")
	
	if body.is_in_group("player"):
		print("[LECTERN] Player entered Lectern 2 area")
		player_in_2 = true
		player = body
		
		# Debug current player state
		if player.has_method("has_items") and player.has_items():
			var current_item = player.held_items[player.selected_item_index] if not player.held_items.is_empty() else null
			print("[LECTERN] Player is holding: ", current_item.name if current_item else "None")
		else:
			print("[LECTERN] Player has no items")
		
		# Debug current lectern state
		print("[LECTERN] Book on Lectern 2: ", book_on_lectern2.name if book_on_lectern2 else "None")

func _on_lectern_3_body_entered(body: Node2D) -> void:
	print("\n[LECTERN] Body entered Lectern 3 area: ", body.name)
	print("[LECTERN] Body position: ", body.global_position)
	print("[LECTERN] Lectern 3 position: ", lecturn3.global_position if lecturn3 else "Not found")
	
	if body.is_in_group("player"):
		print("[LECTERN] Player entered Lectern 3 area")
		player_in_3 = true
		player = body
		
		# Debug current player state
		if player.has_method("has_items") and player.has_items():
			var current_item = player.held_items[player.selected_item_index] if not player.held_items.is_empty() else null
			print("[LECTERN] Player is holding: ", current_item.name if current_item else "None")
		else:
			print("[LECTERN] Player has no items")
		
		# Debug current lectern state
		print("[LECTERN] Book on Lectern 3: ", book_on_lectern3.name if book_on_lectern3 else "None")

func _on_lectern_1_body_exited(body: Node2D) -> void:
	print("\n[LECTERN] Body exited Lectern 1 area: ", body.name)
	
	if body.is_in_group("player"):
		print("[LECTERN] Player exited Lectern 1 area")
		player_in_1 = false
		# Only hide text if it's showing our tooltip and not another message
		if text_box and text_box.visible and text_box.text.begins_with("Press"):
			text_box.visible = false
		if dialogue and dialogue.visible:
			dialogue.visible = false
		
		# Debug final state when exiting
		print("[LECTERN] Final state of Lectern 1:")
		print("  - player_in_1: ", player_in_1)
		print("  - Book on lectern: ", book_on_lectern1.name if book_on_lectern1 else "None")
		if book_on_lectern1 and book_on_lectern1 is RigidBody2D:
			print("  - Book physics state:")
			print("    - gravity_scale: ", book_on_lectern1.gravity_scale)
			print("    - freeze: ", book_on_lectern1.freeze)
			print("    - sleeping: ", book_on_lectern1.sleeping)
			print("    - collision_layer: ", book_on_lectern1.collision_layer)
			print("    - collision_mask: ", book_on_lectern1.collision_mask)

func _on_lectern_2_body_exited(body: Node2D) -> void:
	print("\n[LECTERN] Body exited Lectern 2 area: ", body.name)
	
	if body.is_in_group("player"):
		print("[LECTERN] Player exited Lectern 2 area")
		player_in_2 = false
		# Only hide text if it's showing our tooltip and not another message
		if text_box and text_box.visible and text_box.text.begins_with("Press"):
			text_box.visible = false
		if dialogue and dialogue.visible:
			dialogue.visible = false
		
		# Debug final state when exiting
		print("[LECTERN] Final state of Lectern 2:")
		print("  - player_in_2: ", player_in_2)
		print("  - Book on lectern: ", book_on_lectern2.name if book_on_lectern2 else "None")
		if book_on_lectern2 and book_on_lectern2 is RigidBody2D:
			print("  - Book physics state:")
			print("    - gravity_scale: ", book_on_lectern2.gravity_scale)
			print("    - freeze: ", book_on_lectern2.freeze)
			print("    - sleeping: ", book_on_lectern2.sleeping)
			print("    - collision_layer: ", book_on_lectern2.collision_layer)
			print("    - collision_mask: ", book_on_lectern2.collision_mask)

func _on_lectern_3_body_exited(body: Node2D) -> void:
	print("\n[LECTERN] Body exited Lectern 3 area: ", body.name)
	
	if body.is_in_group("player"):
		print("[LECTERN] Player exited Lectern 3 area")
		player_in_3 = false
		# Only hide text if it's showing our tooltip and not another message
		if text_box and text_box.visible and text_box.text.begins_with("Press"):
			text_box.visible = false
		if dialogue and dialogue.visible:
			dialogue.visible = false
		
		# Debug final state when exiting
		print("[LECTERN] Final state of Lectern 3:")
		print("  - player_in_3: ", player_in_3)
		print("  - Book on lectern: ", book_on_lectern3.name if book_on_lectern3 else "None")
		if book_on_lectern3 and book_on_lectern3 is RigidBody2D:
			print("  - Book physics state:")
			print("    - gravity_scale: ", book_on_lectern3.gravity_scale)
			print("    - freeze: ", book_on_lectern3.freeze)
			print("    - sleeping: ", book_on_lectern3.sleeping)
			print("    - collision_layer: ", book_on_lectern3.collision_layer)
			print("    - collision_mask: ", book_on_lectern3.collision_mask)
