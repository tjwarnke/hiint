extends Sprite2D

@onready var area = $Area2D
var player_nearby = false
var dialogue_active = false
var player = null
var cut_scene_seen = false

@onready var text_box = get_node("/root/World/Level/UI/TextBoxMiddleTop")
@onready var text_box2 = get_node("/root/World/Level/UI/TextBoxMiddleTop2")
@onready var dialogue = get_node("/root/World/Level/UI/DialogOptions")
@onready var sprite = get_node("/root/World/Level/UI/Speaker")
@onready var Box1 = get_node("/root/World/Level/UI/TextBoxMiddleTopBack")
@onready var Box2 = get_node("/root/World/Level/UI/TextBoxMiddleTopBack2")
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
			text_box.visible = true
			Box2.visible = true
			text_box.text = "Welcome to the Kusnetzov Mansion!"
			await get_tree().create_timer(2).timeout
			text_box2.visible = true
			text_box2.text = "Take a seat at the table!"
			await get_tree().create_timer(2).timeout
			text_box2.visible = false
			text_box.text = "The dinner will start shortly!"
			await get_tree().create_timer(2).timeout
			text_box.visible = false
			sprite.visible = false
			Box2.visible = false
			cut_scene_seen = true
		
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		
		
		
