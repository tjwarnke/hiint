extends Area2D

var player = null
@onready var butler = get_node_or_null("../ButlerLarge")

func _ready():
	self.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
	butler.visible = false
