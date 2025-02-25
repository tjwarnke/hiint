extends Node2D

var PlayerScene = preload("res://Player.tscn")  
var player

@onready var spawn = $Level/Spawn
@onready var start_menu = $StartMenu  # Reference to StartMenu
@onready var level = $Level

func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Start with StartMenu visible and wait for player to press start
	start_menu.show()
	level.hide()  # Hide level at the start


func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func start_game():
	start_menu.hide()  # Hide menu
	level.show()  # Show the level
	spawn_player()  # Spawn the player

func spawn_player():
	player = PlayerScene.instantiate()
	add_child(player)
	var floor_top = spawn.global_position.y - (spawn.get_node("CollisionShape2D").shape.extents.y)
	player.global_position = Vector2(spawn.global_position.x, floor_top - 20)  

func on_power_up(power_type: Variant) -> void:
	player.on_power_up_collected(power_type)
