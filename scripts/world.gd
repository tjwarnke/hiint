extends Node2D

var PlayerScene = preload("res://scenes/Player.tscn")  
var player

@onready var spawn = $Level/Spawn
@onready var level = $Level
@onready var camera = $Camera2D  
@onready var jumpscare = $Camera2D/Jumpscare
@onready var jumpscare_timer = $Camera2D/Timer  
@onready var jumpscare_noise = $Camera2D/AudioStreamPlayer
@onready var moon = $Moon
@onready var darkness = $Camera2D/CanvasModulate
var AmbientNoiseScene = preload("res://scenes/ambient_noise.tscn")  
var ambient_noise  
@onready var dining_wall = $DiningRoom/Wall
@onready var dining_threshold = $DiningRoom/dining_bounds
@onready var dining_camera_target = $DiningRoom/CameraTarget  

var moving_player = false
var move_distance = 500
var move_speed = 100.0

func _ready():
	level.show()
	darkness.show()
	$Level/Torch.show()
	spawn_player()
	jumpscare_timer.timeout.connect(hide_jumpscare)  
	MainMusic.fade_out_music()

	ambient_noise = AmbientNoiseScene.instantiate()
	add_child(ambient_noise)
	dining_threshold.body_entered.connect(_on_dining_threshold_entered)

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("p"):
		show_jumpscare()
		jumpscare_noise.play()
	if Input.is_action_just_pressed("set_down"):
		player.drop_item()



	if moving_player:
		player.position.x += move_speed * _delta
		move_distance -= move_speed * _delta
		if move_distance <= 0:
			moving_player = false  
			player.set_can_move(true)
			drop_wall()  # Drop the wall only after player finishes moving

func show_jumpscare():
	jumpscare.show()
	jumpscare_timer.start()

func hide_jumpscare():
	jumpscare.hide()

func start_game():
	var title_music = get_node("StartMenu/AudioStreamPlayer2D")
	title_music.fade_out_music()	
	level.show()
	darkness.show()
	$Level/Torch.show()
	$TorchLight.show()
	moon.position.x = (camera.position.x * 0.5) + 1500  
	moon.position.y = camera.position.y - 550  
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

func _on_dining_threshold_entered(body):
	if body == player:
		await wait_until_grounded()  # Wait for player to be on ground
		move_camera_to_target()
		move_player_slowly()

func wait_until_grounded():
	while not player.is_on_floor():  
		await get_tree().process_frame  

func move_camera_to_target():
	var tween = create_tween()
	tween.tween_property(camera, "position", dining_camera_target.global_position, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished  # Wait for the camera movement to complete

	# Set new camera constraints after reaching the target
	adjust_camera_bounds()

func adjust_camera_bounds():
	# Set left camera limit to the dining threshold position
	camera.limit_left = dining_threshold.global_position.x  

	# Unlock horizontal movement (remove right limit)
	camera.limit_right = 999999  # Effectively unlocks movement  

	# Unlock vertical movement but set default Y offset
	camera.offset = Vector2(0, -100)  
	camera.limit_top = -999999  # No top limit  
	camera.limit_bottom = 999999  # No bottom limit 
	
	
func move_player_slowly():
	player.set_can_move(false)
	moving_player = true

func drop_wall():
	dining_wall.freeze = false  
	dining_wall.apply_central_impulse(Vector2(0, -300))  
