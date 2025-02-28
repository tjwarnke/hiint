extends Node2D

var PlayerScene = preload("res://Player.tscn")  
var player

@onready var spawn = $Level/Spawn
@onready var start_menu = $StartMenu  
@onready var level = $Level
@onready var camera = $Camera2D  # Reference to Camera2D in the World scene
@onready var jumpscare = $Camera2D/Jumpscare
@onready var jumpscare_timer = $Camera2D/Timer  # Reference to Timer node
@onready var jumpscare_noise = $Camera2D/AudioStreamPlayer

func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	jumpscare.hide()
	start_menu.show()
	level.hide()
	jumpscare_timer.timeout.connect(hide_jumpscare)  # Hide jumpscare after timer ends

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("p"):
		show_jumpscare()
		jumpscare_noise.play()
		
	# Make the camera follow the player horizontally only
	if player:
		camera.position.x = player.position.x  # Follow X movement
		camera.position.y = camera.position.y  # Keep Y fixed


func show_jumpscare():
	jumpscare.show()
	jumpscare_timer.start()
	

func hide_jumpscare():
	jumpscare.hide()


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
	
