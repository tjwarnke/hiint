extends StaticBody2D

@onready var area = $Area2D
var player_nearby = false
var text_box = null
var text_box_ready = false

signal text_box_found

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	# Start looking for the text box
	look_for_text_box()

func look_for_text_box():
	# Try to find the text box in different possible paths
	var possible_paths = [
		"/root/World/Level/UI/TextBoxMiddleTop",
		"/root/World/Tutorial/UI/TextBoxMiddleTop",
		
		"/root/World/Tutorial/UI/TextBoxMiddleTopBack"
	]
	
	for path in possible_paths:
		text_box = get_node_or_null(path)
		if text_box:
			text_box_ready = true
			text_box_found.emit()
			return
	
	# If not found, wait a bit and try again
	await get_tree().create_timer(0.1).timeout
	look_for_text_box()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		if text_box_ready and text_box:
			# Get the current key binding for pick_up action
			var key = InputMap.action_get_events("pick_up")[0].as_text()
			# Remove the "(physical)" part if present
			if "(" in key:
				key = key.split("(")[0].strip_edges()
			text_box.text = "Press '%s' to examine stump" % key
			text_box.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		if text_box_ready and text_box:
			text_box.visible = false

func _input(event):
	if event.is_action_pressed("pick_up") and player_nearby:
		if text_box_ready and text_box:
			text_box.text = "This is an old tree stump. It looks like it was cut down recently."
			text_box.visible = true 
