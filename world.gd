extends Node2D

var PlayerScene = preload("res://Player.tscn")  # Load Player scene

@onready var floor = $Floor

func _ready():
	# Set the game to fullscreen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	spawn_player()

func _process(delta):
	# Quit the game when Escape is pressed
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func spawn_player():
	var player = PlayerScene.instantiate()  # Create a new player instance
	add_child(player)  # Add to the scene

	# Position the player above the floor
	var floor_top = floor.global_position.y - (floor.get_node("CollisionShape2D").shape.extents.y)
	player.global_position = Vector2(floor.global_position.x, floor_top - 20)  # Offset to avoid overlap
