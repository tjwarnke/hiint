extends Area2D

var player_nearby = false
@onready var text = get_node("/root/World/UI/TextBoxMiddleTop")
var player = null
var talked = false

func _ready():
	self.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.is_in_group("player") and talked == false:
		player_nearby = true
		player = body
		text.visible = true
		text.text = "You have collected Dash!"
		await get_tree().create_timer(1).timeout
		text.visible = false
		talked = true
