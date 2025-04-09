extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var talked = 0

var text_box = null
var dialogue = null

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	text_box = get_node_or_null("../../UI/TextBoxMiddleTop")
	dialogue = get_node_or_null("../../UI/DialogOptions")
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		player = body
		text_box.visible = true
		text_box.text = "Press 'f' to take a seat"
		
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		await get_tree().create_timer(1.5).timeout
		text_box.visible = false
		dialogue.visible = false
		
func options(response):
	dialogue.visible = false
	text_box.visible = true
	text_box.text = response
	await get_tree().create_timer(2).timeout
	
func base_dialog():
	dialogue.text = "1. Mysterious Trench Coater \n2. Sargent Relish \n3. Mr. Conman \n4. Leave"
	dialogue.visible = true
	dialogue_active = true

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		player.set_can_move(false)
		dialogue_active = false
		dialogue.visible = false
		
		if talked == 3:
			text_box.text = "You already talked to everyone."
			text_box.visible = true
			player.set_can_move(true)
			await get_tree().create_timer(1.5).timeout
			text_box.visible = false
			
		else:
			text_box.text = "You have taken a seat at the table"
			text_box.visible = true
			await get_tree().create_timer(2).timeout
			base_dialog()
			
	if dialogue_active:
			if event.is_action_pressed("Option1"):
				talked +=1
				options("Hello I am the Mysterious Trench Coater")
				await get_tree().create_timer(1.5).timeout
				text_box.text = "Who would you like to talk to?"
				base_dialog()
				
			if event.is_action_pressed("Option2"):
				talked +=1
				options("Hello I am Sargent Relish")
				await get_tree().create_timer(1.5).timeout
				text_box.text = "Who would you like to talk to?"
				base_dialog()
				
			if event.is_action_pressed("Option3"):
				talked +=1
				options("Hello I am the Mysterious Trench Coater")
				await get_tree().create_timer(1.5).timeout
				text_box.text = "Who would you like to talk to?"
				base_dialog()
				
			if event.is_action_pressed("Option4"):
				player.set_can_move(true)
				text_box.visible = false
				dialogue.visible = false
