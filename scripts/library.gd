extends Node2D

var player_in_1 = false # tracks if player is close enough to interact with lectern 1
var player_in_2 = false
var player_in_3 = false

var lec1 = false # Tracks the state of the lectern1
var lec2 = false
var lec3 = false

var hasNanas = false # Tracks if player has Nana's autobiography
var hasAnnas = false
var hasVlads = false

var dialogue_active = false
var text_box = null
var dialogue = null

var book_on_lectern1 = null # Holds the reference to the book on lectern 1
var book_on_lectern2 = null
var book_on_lectern3 = null

var player
var vlads
var annas
var nanas

func _ready():
	player = get_node("/root/World/Player")
	print(player)
	text_box = get_node_or_null("../UI/TextBoxMiddleTop")
	dialogue = get_node_or_null("../UI/DialogOptions")
	vlads = get_node("Vlad_Autobiography")
	annas = get_node("Anna_Autobiography")
	nanas = get_node("Nana_Autobiography")
	
	if not text_box:
		push_warning("TextBoxMiddleTop not found in scene")
	if not dialogue:
		push_warning("DialogOptions not found in scene")
	
func _input(event):
	if event.is_action_pressed("pick_up") and player_in_1:
		lectern(event, 1)
	if event.is_action_pressed("pick_up") and player_in_2:
		lectern(event, 2)
	if event.is_action_pressed("pick_up") and player_in_3:
		lectern(event, 3)
		
func lectern(event, number):
	if number == 1 and lec1:
		text_box.text = "You take the book from the lectern"
		player.pick_up(book_on_lectern1)
		book_on_lectern1 == null
		#TODO: show the book on the lectern
	elif number == 2 and lec2:
		text_box.text = "You take the book from the lectern"
		player.pick_up(book_on_lectern2)
		book_on_lectern2 == null
	elif number == 2 and lec2:
		text_box.text = "You take the book from the lectern"
		player.pick_up(book_on_lectern3)
		book_on_lectern3 == null
	else:
		text_box.text = "A lectern sits, awaiting a book."
		text_box.visible = true
		await get_tree().create_timer(2).timeout
		text_box.text = "Place a book?"
		await get_tree().create_timer(1).timeout
		if player.has_method("has_item"):
			hasNanas = player.has_item("Nana_Autobiography")
			hasAnnas = player.has_item("Anna_Autobiography")
			hasVlads = player.has_item("Vlad_Autobiography")
		var books_collected = ""
		if hasAnnas:
			books_collected += "A"
		if hasNanas:
			books_collected += "N"
		if hasVlads:
			books_collected += "V"
		dialogue.text = ""
		if books_collected == "A":
			dialogue.text = "1: Place Anna's Autobiography"
		if books_collected == "N":
			dialogue.text = "1: Place Nana's Autobiography"
		if books_collected == "V":
			dialogue.text = "1: Place Vlads's Autobiography"
		if books_collected == "AN":
			dialogue.text = "1: Place Anna's Autobiography\n2: Place Nana's Autobiography"
		if books_collected == "AV":
			dialogue.text = "1: Place Anna's Autobiography\n2: Place Vlad's Autobiography"
		if books_collected == "NV":
			dialogue.text = "1: Place Nana's Autobiography\n2: Place Vlad's Autobiography"
		if books_collected == "ANV":
			dialogue.text = "1: Place Anna's Autobiography\n2: Place Nana's Autobiography\n3: Place Vlad's Autobiography"
			
		dialogue.visible = true
		dialogue_active = true
		
		if dialogue_active:
			if books_collected == "ANV":	
				if event.is_action_pressed("Option1"):
					give_dialogue("You have placed Anna's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = annas 
					if number == 2:
						book_on_lectern2 = annas
						lec2 = true
					if number == 3:
						book_on_lectern3 = annas
					player.drop_item(annas)
				if event.is_action_pressed("Option2"):
					give_dialogue("You have placed Nana's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = nanas 
						lec1 == true
					if number == 2:
						book_on_lectern2 = nanas
					if number == 3:
						book_on_lectern3 = nanas
					player.drop_item(nanas)
				if event.is_action_pressed("Option3"):
					give_dialogue("You have placed Vlad's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = vlads
					if number == 2:
						book_on_lectern2 = vlads
					if number == 3:
						book_on_lectern3 = vlads
						lec3 == true
					player.drop_item(vlads)
					
			if books_collected == "AN":	
				if event.is_action_pressed("Option1"):
					give_dialogue("You have placed Anna's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = annas 
					if number == 2:
						book_on_lectern2 = annas
						lec2 = true
					if number == 3:
						book_on_lectern3 = annas
					player.drop_item(annas)
				if event.is_action_pressed("Option2"):
					give_dialogue("You have placed Nana's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = nanas 
						lec1 == true
					if number == 2:
						book_on_lectern2 = nanas
					if number == 3:
						book_on_lectern3 = nanas
					player.drop_item(nanas)
					
			if books_collected == "AV":	
				if event.is_action_pressed("Option1"):
					give_dialogue("You have placed Anna's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = annas 
					if number == 2:
						book_on_lectern2 = annas
						lec2 = true
					if number == 3:
						book_on_lectern3 = annas
					player.drop_item(annas)
				if event.is_action_pressed("Option2"):
					give_dialogue("You have placed Vlad's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = vlads
					if number == 2:
						book_on_lectern2 = vlads
					if number == 3:
						book_on_lectern3 = vlads
						lec3 == true
					player.drop_item(vlads)
					
			if books_collected == "NV":	
				if event.is_action_pressed("Option1"):
					give_dialogue("You have placed Nana's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = nanas 
						lec1 == true
					if number == 2:
						book_on_lectern2 = nanas
					if number == 3:
						book_on_lectern3 = nanas
					player.drop_item(nanas)
				if event.is_action_pressed("Option2"):
					give_dialogue("You have placed Vlad's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = vlads
					if number == 2:
						book_on_lectern2 = vlads
					if number == 3:
						book_on_lectern3 = vlads
						lec3 == true
					player.drop_item(vlads)
					
			if books_collected == "A":	
				if event.is_action_pressed("Option1"):
					give_dialogue("You have placed Anna's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = annas 
					if number == 2:
						book_on_lectern2 = annas
						lec2 = true
					if number == 3:
						book_on_lectern3 = annas
					player.drop_item(annas)
					
			if books_collected == "N":
				if event.is_action_pressed("Option1"):
					give_dialogue("You have placed Nana's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = nanas 
						lec1 == true
					if number == 2:
						book_on_lectern2 = nanas
					if number == 3:
						book_on_lectern3 = nanas
					player.drop_item(nanas)
					
			if books_collected == "V":	
				if event.is_action_pressed("Option1"):
					give_dialogue("You have placed Vlad's Autobiography on the lectern")
					if number == 1:
						book_on_lectern1 = vlads
					if number == 2:
						book_on_lectern2 = vlads
					if number == 3:
						book_on_lectern3 = vlads
						lec3 == true
					player.drop_item(vlads)
				
		check_puzzle()
		
func check_puzzle():
	if lec1 and lec2 and lec3:
		open_door()

func open_door():
	pass #TODO: open the door
	
func _on_lectern_1_body_entered(body: Node2D) -> void:
	player_in_1 = true

func _on_lectern_2_body_entered(body: Node2D) -> void:
	player_in_2 = true

func _on_lectern_3_body_entered(body: Node2D) -> void:
	player_in_3 = true

func _on_lectern_1_body_exited(body: Node2D) -> void:
	player_in_1 = false

func _on_lectern_2_body_exited(body: Node2D) -> void:
	player_in_2 = false

func _on_lectern_3_body_exited(body: Node2D) -> void:
	player_in_3 = false

func give_dialogue(response):
	dialogue.visible = false
	text_box.text = response
	dialogue_active = false
	#player.pick_up_item(book)
	player.set_can_move(true)
	await get_tree().create_timer(2).timeout
	text_box.visible = false
