extends Node2D

var PlayerScene = preload("res://Player.tscn")  
var player

@onready var spawn = $Level/Spawn
@onready var start_menu = $StartMenu  
@onready var level = $Level
@onready var camera = $Camera2D  # Reference to Camera2D in the World scene

func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	start_menu.show()
	level.hide()

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	# Make the camera follow the player horizontally only
	if player:
		camera.position.x = player.position.x  # Follow X movement
		camera.position.y = camera.position.y  # Keep Y fixed

func start_game():
	start_menu.hide()
	level.show()
	spawn_player()

func spawn_player():
	player = PlayerScene.instantiate()
	add_child(player)
	var floor_top = spawn.global_position.y - (spawn.get_node("CollisionShape2D").shape.extents.y)
	player.global_position = Vector2(spawn.global_position.x + 40, floor_top - 20)

func on_power_up(power_type: Variant) -> void:
	player.on_power_up_collected(power_type)
