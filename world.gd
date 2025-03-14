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
@onready var moon = $Moon
@onready var darkness = $Camera2D/CanvasModulate


func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	jumpscare.hide()
	$TorchLight.hide()
	moon.hide()
	darkness.hide()
	start_menu.show()
	level.hide()
	jumpscare_timer.timeout.connect(hide_jumpscare)  # Hide jumpscare after timer ends

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("p"):
		show_jumpscare()
		jumpscare_noise.play()
	if Input.is_action_just_pressed("set_down"):
		player.drop_item()
		
		
		
	moon.position.x = ((camera.position.x) + 1050) * 0.85
		
#
		
#


func show_jumpscare():
	jumpscare.show()
	jumpscare_timer.start()
	

func hide_jumpscare():
	jumpscare.hide()


func start_game():
	start_menu.hide()
	level.show()
	darkness.show()
	$Level/Torch.show()
	$TorchLight.show()
	moon.position.x = (camera.position.x * 0.5) + 1500  # Adjust 0.5 to change speed
	moon.position.y = camera.position.y  - 550 # Adjust for vertical parallax
	moon.show()
	spawn_player()
	
func spawn_player():
	player = PlayerScene.instantiate()
	camera.player = player
	add_child(player)
	var floor_top = spawn.global_position.y - (spawn.get_node("CollisionShape2D").shape.extents.y)
	player.global_position = Vector2(spawn.global_position.x + 40, floor_top - 20)

func on_power_up(power_type: Variant) -> void:
	player.on_power_up_collected(power_type)

func _on_torch_picked() -> void:
	$TorchLight.hide()
	$TorchLight/ReferenceRect.hide()
