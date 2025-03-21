extends Node2D

# Load player scene
var PlayerScene = preload("res://scenes/Player.tscn")  
var player

# Nodes
@onready var spawn = $Level/Spawn
@onready var level = $Level
@onready var camera = $Camera2D  
@onready var jumpscare = $Camera2D/Jumpscare
@onready var jumpscare_timer = $Camera2D/Timer  
@onready var jumpscare_noise = $Camera2D/AudioStreamPlayer
@onready var moon = $Moon
@onready var darkness = $Camera2D/CanvasModulate
@onready var dining_wall = $DiningRoom/Wall
@onready var dining_threshold = $DiningRoom/dining_bounds
@onready var ambient_noise = preload("res://scenes/ambient_noise.tscn").instantiate()
var moving_player = false
var move_distance = 500
var move_speed = 100.0
var camera_smooth_speed = 0.0001  # Adjust this value for smoother/slower movement
@onready var wall_fall = $DiningRoom/WallFall

func _ready():
	level.show()
	darkness.show()
	$Level/Torch.show()
	spawn_player()
	jumpscare_timer.timeout.connect(hide_jumpscare)  
	MainMusic.fade_out(MainMusic)

	# Add ambient noise
	add_child(ambient_noise)

	# Connect dining threshold trigger
	if dining_threshold:
		dining_threshold.body_entered.connect(_on_dining_threshold_entered)
	else:
		print("Error: dining_threshold is missing!")

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("p"):
		show_jumpscare()
		jumpscare_noise.play()
	if Input.is_action_just_pressed("set_down"):
		player.drop_item()

	if moving_player:
		player.position.x += move_speed * delta
		move_distance -= move_speed * delta
		if move_distance <= 0:
			moving_player = false  
			player.set_can_move(true)
			drop_wall()

	# Smoothly move the camera towards the player's new position
	camera.position = camera.position.lerp(player.position, camera_smooth_speed * delta)

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
		await wait_until_grounded()  # Ensure player is stable before continuing
		update_camera_bounds()  # Update camera dynamically instead of moving
		move_player_slowly()
		ambient_noise.on_dining()
		darkness.set_color(Color("ffeea4"))
		
		

func wait_until_grounded():
	while not player.is_on_floor():  
		await get_tree().process_frame  

func update_camera_bounds():
	if not dining_threshold:
		print("Error: dining_threshold is null!")
		return

	# Lock camera's left side at dining_threshold's position
	camera.limit_left = dining_threshold.global_position.x  

	# Effectively remove limits in all other directions
	camera.limit_right = 999999  # Allow movement to the right indefinitely
	camera.limit_top = -999999   # No limit upwards
	camera.limit_bottom = 999999  # No limit downwards

	# Optional: Adjust camera offset if necessary
	camera.offset = Vector2(0, -100)

	print("Camera bounds updated:", camera.limit_left, camera.limit_right, camera.limit_top, camera.limit_bottom)

func move_player_slowly():
	player.set_can_move(false)
	moving_player = true

func drop_wall():
	wall_fall.play(wall)
	
