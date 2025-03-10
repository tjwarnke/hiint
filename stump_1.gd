extends StaticBody2D

@onready var area = $Area2D
var player_nearby = false

@onready var text_box = get_node("/root/World/Level/UI/TextBoxMiddleTop")

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		await get_tree().create_timer(1.5).timeout
		text_box.visible = false

func _input(event):
	if event.is_action_pressed("Interact2") and player_nearby:
		text_box.text = "This is a stump."
		text_box.visible = true
