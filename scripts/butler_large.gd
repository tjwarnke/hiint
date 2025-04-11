extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var cut_scene_seen = false

@onready var text = get_node("/root/World/UI/TextBoxMiddleTop")
@onready var sprite = get_node("/root/World/UI/Speaker")

var butler = preload("res://assets/images/ButlerHead.png")

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		if cut_scene_seen == false:
			sprite.scale = Vector2(.5, .5)
			player_nearby = true
			sprite.texture = butler
			sprite.visible = true
			text.visible = true
			text.text = "Welcome to the Kusnetzov Mansion!"
			await get_tree().create_timer(2).timeout
			text.text = "Take a seat at the table!"
			await get_tree().create_timer(2).timeout
			text.text = "The dinner will start shortly!"
			await get_tree().create_timer(2).timeout
			text.visible = false
			sprite.visible = false
			cut_scene_seen = true
		
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
