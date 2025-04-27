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

func _ready():
	lecturn1.body_entered.connect( _on_lectern_1_body_entered)
	lecturn2.body_entered.connect( _on_lectern_2_body_entered)
	lecturn3.body_entered.connect( _on_lectern_3_body_entered)
	lecturn1.body_exited.connect( _on_lectern_1_body_exited)
	lecturn2.body_exited.connect( _on_lectern_2_body_exited)
	lecturn3.body_exited.connect( _on_lectern_3_body_exited)
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
	
	# Handle setting down books with 'q' key
	if event.is_action_pressed("set_down") and player and player.has_method("has_items") and player.has_items():
		var current_item = player.held_items[player.selected_item_index] if not player.held_items.is_empty() else null
		if current_item and (current_item.name.contains("Autobiography") or current_item.name.contains("Book")):
			if player_in_1:
				place_book_on_lectern(current_item, 1)
			elif player_in_2:
				place_book_on_lectern(current_item, 2)
			elif player_in_3:
				place_book_on_lectern(current_item, 3)
	
	# Keep existing pick_up logic for taking books from lecterns
	if player_in_1 and event.is_action_pressed("pick_up") and book_on_lectern1:
		lectern(event, 1)
	if player_in_2 and event.is_action_pressed("pick_up") and book_on_lectern2:
		lectern(event, 2)
	if player_in_3 and event.is_action_pressed("pick_up") and book_on_lectern3:
		lectern(event, 3)

func lectern(event, number):
	if number == 1 and book_on_lectern1:
		text_box.text = "You take the book from the lectern"
		player.call_deferred("pick_up", book_on_lectern1)
		book_on_lectern1 = null
		lec1 = false
	elif number == 2 and book_on_lectern2:
		text_box.text = "You take the book from the lectern"
		player.call_deferred("pick_up", book_on_lectern2)
		book_on_lectern2 = null
		lec2 = false
	elif number == 3 and book_on_lectern3:
		text_box.text = "You take the book from the lectern"
		player.call_deferred("pick_up", book_on_lectern3)
		book_on_lectern3 = null
		lec3 = false
		
	check_puzzle()

func check_puzzle():
	# Check if each book is in its correct Area2D
	var puzzle_complete = true
	
	if book_on_lectern1:
		var book_area = book_on_lectern1.get_node_or_null("Area2D")
		if book_area and not book_area.overlaps_area(lecturn1):
			puzzle_complete = false
	else:
		puzzle_complete = false
		
	if book_on_lectern2:
		var book_area = book_on_lectern2.get_node_or_null("Area2D")
		if book_area and not book_area.overlaps_area(lecturn2):
			puzzle_complete = false
	else:
		puzzle_complete = false
		
	if book_on_lectern3:
		var book_area = book_on_lectern3.get_node_or_null("Area2D")
		if book_area and not book_area.overlaps_area(lecturn3):
			puzzle_complete = false
	else:
		puzzle_complete = false
	
	if puzzle_complete:
		open_door()

func open_door():
	var billiards_room = get_node_or_null("/root/World/BilliardsRoom")
	if billiards_room:
		var anim_player = billiards_room.get_node_or_null("AnimationPlayer")
		if anim_player:
			anim_player.play("door open")
			# Show success message
			if text_box:
				text_box.visible = true
				text_box.text = "The door creaks open..."
				await get_tree().create_timer(2).timeout
				text_box.visible = false
		else:
			push_warning("AnimationPlayer not found in billiards room scene")
	else:
		push_warning("Billiards room scene not found")

func place_book_on_lectern(book, lectern_number):
	# Get the lectern's Area2D position
	var lectern_area = null
	if lectern_number == 1:
		lectern_area = lecturn1
		book_on_lectern1 = book
		lec1 = true
	elif lectern_number == 2:
		lectern_area = lecturn2
		book_on_lectern2 = book
		lec2 = true
	elif lectern_number == 3:
		lectern_area = lecturn3
		book_on_lectern3 = book
		lec3 = true
	
	if lectern_area:
		# Use call_deferred for all physics operations
		player.call_deferred("drop_item", book)
		
		# Enable the book's properties using call_deferred
		book.call_deferred("set_visible", true)
		book.call_deferred("set_monitoring", true)
		book.call_deferred("set_monitorable", true)
		book.call_deferred("set_can_be_picked_up", true)
		
		# Enable collision shapes using call_deferred
		for shape in book.get_children():
			if shape is CollisionShape2D or shape is CollisionPolygon2D:
				shape.call_deferred("set_disabled", false)
		
		# Set position and rotation using call_deferred
		book.call_deferred("set_global_position", lectern_area.global_position)
		book.call_deferred("set_rotation", 0)  # Make sure book is not rotated
		
		# Enable physics properties if it's a RigidBody2D
		if book is RigidBody2D:
			book.call_deferred("set_freeze", false)
			book.call_deferred("set_sleeping", false)
			book.call_deferred("set_gravity_scale", 0)  # Prevent falling
		
		# Show feedback message
		if text_box:
			text_box.visible = true
			text_box.text = "You place the book on the lectern"
			await get_tree().create_timer(2).timeout
			text_box.visible = false
		
		# Check if puzzle is complete
		check_puzzle()

@onready var lecturn1 = $Lec1/Lectern1
@onready var lecturn2 = $Lec2/Lectern2
@onready var lecturn3 = $Lec3/Lectern3
	
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
		# Only hide text if it's showing our tooltip and not another message
		if text_box and text_box.visible and text_box.text.begins_with("Press"):
			text_box.visible = false
		if dialogue and dialogue.visible:
			dialogue.visible = false

func _on_lectern_2_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_2 = false
		# Only hide text if it's showing our tooltip and not another message
		if text_box and text_box.visible and text_box.text.begins_with("Press"):
			text_box.visible = false
		if dialogue and dialogue.visible:
			dialogue.visible = false

func _on_lectern_3_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_3 = false
		# Only hide text if it's showing our tooltip and not another message
		if text_box and text_box.visible and text_box.text.begins_with("Press"):
			text_box.visible = false
		if dialogue and dialogue.visible:
			dialogue.visible = false
