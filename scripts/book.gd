extends RigidBody2D

signal item_picked

var can_be_picked_up = true
var player = null
var player_in_area = false  # Track when player is in the item's area

# Store original properties for debugging
var original_scale = Vector2.ZERO
var original_rotation = 0.0
var original_position = Vector2.ZERO
var original_parent = null

# Default book content in case it's a book without specified content
var default_book_content = "This appears to be an old book. The pages are faded and difficult to read."

@onready var text_box = get_node("/root/World/UI/TextBoxMiddleTop")
@onready var sprite = $Sprite2D
@onready var area = get_node("Area2D")

func _ready():
	add_to_group("item")
	add_to_group("books")  # Add to books group for lectern detection
	# Store original properties
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	original_scale = scale
	original_rotation = rotation
	original_position = position
	original_parent = get_parent()
	
	print("[BOOK PUZZLE] Book initialized: ", name)
	print("[BOOK PUZZLE] Initial position: ", global_position)
	print("[BOOK PUZZLE] Initial parent: ", get_parent().name if get_parent() else "None")
	
	# If this is a book and doesn't have content yet, add default content
	if name.contains("Book") or name.contains("Autobiography"):
		if not has_meta("book_content"):
			set_meta("book_content", default_book_content)
	
	# Wait for the Player node to be available
	await get_tree().process_frame
	await get_tree().process_frame  # Wait two frames to ensure World is ready
	
	# Try to find the player node
	var world = get_node_or_null("/root/World")
	if world:
		player = world.get_node_or_null("Player")

# Override _set method to track property changes
func _set(property, value):
	if property == "global_position" or property == "position":
		print("[BOOK] Position changing for ", name, " - New pos: ", value)
		return false  # Continue with normal property setting
	elif property == "gravity_scale" or property == "freeze" or property == "sleeping" or property == "collision_layer" or property == "collision_mask":
		print("[BOOK] Physics property changing: ", property, " = ", value, " for book ", name)
		return false  # Continue with normal property setting
	return false

# Add a new method to monitor when the transform changes
func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		print("[BOOK] Transform changed for ", name, " - New position: ", global_position)

# Add physics process to monitor position
func _physics_process(_delta):
	# Track if this book should be on a lectern
	var library = get_node_or_null("/root/World/Library")
	if library and (library.book_on_lectern1 == self or library.book_on_lectern2 == self or library.book_on_lectern3 == self):
		# This book should be on a lectern, verify its position is stable
		var lectern_number = 0
		var expected_position = Vector2.ZERO
		
		if library.book_on_lectern1 == self:
			lectern_number = 1
			expected_position = Vector2(1627.0, -1527.0)
		elif library.book_on_lectern2 == self:
			lectern_number = 2
			expected_position = Vector2(2073.0, -1536.0)
		elif library.book_on_lectern3 == self:
			lectern_number = 3
			expected_position = Vector2(2525.0, -1520.0)
			
		var distance = global_position.distance_to(expected_position)
		if distance > 5.0:  # If drifted more than 5 pixels
			print("[BOOK PUZZLE] Book ", name, " has drifted ", distance, " pixels from its expected position on lectern ", lectern_number)
			print("[BOOK PUZZLE] Current position: ", global_position, " | Expected: ", expected_position)
			
			# Try to correct position
			global_position = expected_position
			
			# Make sure physics properties are still correct
			if not freeze or not sleeping:
				print("[BOOK PUZZLE] Physics properties have changed, resetting...")
				freeze = true
				sleeping = true
				gravity_scale = 0
				collision_layer = 2
				collision_mask = 0

func _process(_delta):
	# Prioritize pickup if player is in range of an item
	if player and Input.is_action_just_pressed("pick_up") and can_be_picked_up and player_in_area:
		print("[DEBUG] Book pickup initiated for: ", name)
		print("[DEBUG] Book physics state before pickup:")
		print("  - gravity_scale: ", gravity_scale)
		print("  - freeze: ", freeze)
		print("  - sleeping: ", sleeping)
		print("  - collision_layer: ", collision_layer)
		print("  - collision_mask: ", collision_mask)
		
		can_be_picked_up = false  # Prevent multiple pickups
		emit_signal("item_picked")
		# Disable all physics properties
		self.gravity_scale = 0
		self.freeze = true
		self.sleeping = true
		self.collision_layer = 0  # Disable all collision layers
		self.collision_mask = 0   # Disable all collision masks
		
		print("[DEBUG] Book physics state after pickup:")
		print("  - gravity_scale: ", gravity_scale)
		print("  - freeze: ", freeze)
		print("  - sleeping: ", sleeping)
		print("  - collision_layer: ", collision_layer)
		print("  - collision_mask: ", collision_mask)
		
		player.pick_up_item(self)
		text_box.visible = false  # Hide tooltip after pickup
		return  # Exit early to prevent dialog from showing
	
	# Show tooltip for selected book
	if player and player.has_method("get_selected_item"):
		var selected_item = player.get_selected_item()
		if selected_item == self and (name.contains("Book") or name.contains("Autobiography")):
			text_box.visible = true
			var key = InputMap.action_get_events("pick_up")[0].as_text()
			# Remove the "(physical)" part if present
			if key.contains("(physical)"):
				key = key.split(" (physical)")[0]
			text_box.text = "Press '%s' to read book" % key
			
			# If the player presses the key to read the book
			if Input.is_action_just_pressed("pick_up"):
				text_box.text = get_meta("book_content")
				# Create a timer to keep the text visible longer
				var timer = get_tree().create_timer(5.0)  # Show text for 5 seconds
				await timer.timeout
				# Only reset the text if this is still the selected item
				if player and player.has_method("get_selected_item") and player.get_selected_item() == self:
					key = InputMap.action_get_events("pick_up")[0].as_text()
					# Remove the "(physical)" part if present
					if key.contains("(physical)"):
						key = key.split(" (physical)")[0]
					text_box.text = "Press '%s' to read book" % key
		elif selected_item != self:
			text_box.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		player_in_area = true  # Set player_in_area to true when player enters
		# Only show pickup text if this isn't the currently selected item
		if can_be_picked_up and not (player.has_method("get_selected_item") and player.get_selected_item() == self):
			text_box.visible = true
			# Get the current key binding for pick_up action
			var key = InputMap.action_get_events("pick_up")[0].as_text()
			# Remove the "(physical)" part if present
			if "(" in key:
				key = key.split("(")[0].strip_edges()
			if name.contains("Book") or name.contains("Autobiography"):
				text_box.text = "Press '%s' to pick up book" % key
			else:
				text_box.text = "Press '%s' to pick up" % key

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null
		player_in_area = false  # Set player_in_area to false when player exits
		text_box.visible = false

# Override _on_dropped to add more debugging
func _on_dropped():
	print("\n[BOOK PUZZLE] Book dropped: ", name)
	print("[BOOK PUZZLE] Book position: ", global_position)
	print("[BOOK PUZZLE] Book parent: ", get_parent().name if get_parent() else "None")
	
	# Check if this book is on a lectern - if so, don't modify its physics properties
	var on_lectern = false
	var library = get_node_or_null("/root/World/Library")
	var being_processed_by_library = false
	
	if library:
		print("[BOOK PUZZLE] Library found, checking book placement...")
		print("  - book_on_lectern1: ", library.book_on_lectern1.name if library.book_on_lectern1 else "None")
		print("  - book_on_lectern2: ", library.book_on_lectern2.name if library.book_on_lectern2 else "None")
		print("  - book_on_lectern3: ", library.book_on_lectern3.name if library.book_on_lectern3 else "None")
		
		# Check if this book is currently in the process of being placed by the library
		being_processed_by_library = library.is_placing_book
		
		if being_processed_by_library:
			print("[BOOK PUZZLE] This book is currently being placed by the library - skipping _on_dropped handling")
			return
		
		if library.book_on_lectern1 == self:
			on_lectern = true
			print("[BOOK PUZZLE] This book is on lectern 1")
		elif library.book_on_lectern2 == self:
			on_lectern = true
			print("[BOOK PUZZLE] This book is on lectern 2")
		elif library.book_on_lectern3 == self:
			on_lectern = true
			print("[BOOK PUZZLE] This book is on lectern 3")
	else:
		print("[BOOK PUZZLE] Library node not found")
	
	if not on_lectern:
		print("[DEBUG] Book is NOT on a lectern - resetting physics properties")
		# This is a normal drop, reset to original scale
		scale = original_scale
		rotation = original_rotation
		
		# Make sure the item is visible and can be picked up again
		visible = true
		can_be_picked_up = true
		
		# Reset physics properties
		self.gravity_scale = 1.0
		self.freeze = false
		self.sleeping = false
		self.collision_layer = 1  # Enable default collision layer
		self.collision_mask = 1   # Enable default collision mask
		
		print("[DEBUG] Book physics state after reset:")
		print("  - gravity_scale: ", gravity_scale)
		print("  - freeze: ", freeze)
		print("  - sleeping: ", sleeping)
		print("  - collision_layer: ", collision_layer)
		print("  - collision_mask: ", collision_mask)
	else:
		print("[DEBUG] Book IS on a lectern - maintaining special physics properties")
		print("[DEBUG] Book special physics properties being set:")
		
		# Even if on a lectern, set these explicitly to make sure
		self.freeze = true
		self.sleeping = true
		self.gravity_scale = 0
		self.collision_layer = 2  # Set to a different layer than player (layer 2)
		self.collision_mask = 0   # Don't need the book to detect collisions
		self.linear_velocity = Vector2.ZERO
		self.angular_velocity = 0
		
		# Most important - make sure the book stays visible!
		self.visible = true
		
		print("[DEBUG] Book physics state after lectern property setup:")
		print("  - gravity_scale: ", gravity_scale)
		print("  - freeze: ", freeze)
		print("  - sleeping: ", sleeping)
		print("  - collision_layer: ", collision_layer)
		print("  - collision_mask: ", collision_mask)
		print("  - linear_velocity: ", linear_velocity)
		print("  - angular_velocity: ", angular_velocity)
	
	# Reset the player reference and area state
	player = null
	player_in_area = false
	
	print("[DEBUG] Book drop complete for: ", name, "\n")
