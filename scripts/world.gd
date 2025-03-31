extends Node2D

# Load player scene
var PlayerScene = preload("res://scenes/Player.tscn")  
var player

# Scene paths
const DINING_ROOM_PATH = "res://scenes/dining_room.tscn"
const LIBRARY_PATH = "res://scenes/Library.tscn"
const BILLIARDS_ROOM_PATH = "res://scenes/billiards_room.tscn"
const DUNGEON_PATH = "res://scenes/dungeon.tscn"
const TUTORIAL_PATH = "res://scenes/second_tutoiral.tscnd"

# Nodes
@onready var spawn = $Spawn
@onready var camera = $Camera2D  
@onready var jumpscare = $Camera2D/Jumpscare
@onready var jumpscare_timer = $Camera2D/Timer  
@onready var jumpscare_noise = $Camera2D/AudioStreamPlayer
@onready var darkness = $Camera2D/CanvasModulate
@onready var ambient_noise = preload("res://scenes/ambient_noise.tscn").instantiate()

# Dining room nodes (will be set after scene is loaded)
var dining_wall = null
var dining_threshold = null
var wall_fall = null


var scenes_to_load = [
	"res://scenes/tutorial.tscn",
	"res://scenes/dining_room.tscn",
	"res://scenes/library.tscn",
	"res://scenes/billiards_room.tscn",
	"res://scenes/dungeon.tscn"
]

var loaded_scenes = {}

var moving_player = false
var move_distance = 500
var move_speed = 100.0
var camera_smooth_speed = 0.0001  # Adjust this value for smoother/slower movement

func _ready():
	load_next_scene(0)
	# Initialize game state
	initialize_game_state()
	

func _process(delta):
	# Handle input
	handle_input()
	
	# Handle player movement
	handle_player_movement(delta)
	
	# Update camera
	update_camera(delta)
	

func initialize_game_state():
	darkness.show()
	$cabin/Torch.show()
	spawn_player()
	jumpscare_timer.timeout.connect(hide_jumpscare)  
	MainMusic.fade_out(MainMusic)

	# Add ambient noise
	add_child(ambient_noise)

func handle_input():
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("p"):
		show_jumpscare()
		jumpscare_noise.play()
	if Input.is_action_just_pressed("set_down"):
		player.drop_item()

func handle_player_movement(delta):
	if moving_player:
		player.position.x += move_speed * delta
		move_distance -= move_speed * delta
		if move_distance <= 0:
			moving_player = false  
			drop_wall()
			player.drop_item()

func update_camera(delta):
	camera.position = camera.position.lerp(player.position, camera_smooth_speed * delta)

func show_jumpscare():
	jumpscare.show()
	jumpscare_timer.start()

func hide_jumpscare():
	jumpscare.hide()

func start_game():
	var title_music = get_node("StartMenu/AudioStreamPlayer2D")
	if title_music:
		title_music.fade_out_music()  
	darkness.show()
	$Level/Torch.show()
	$TorchLight.show()
	spawn_player()
	
func spawn_player():
	player = PlayerScene.instantiate()
	if player == null:
		print("Failed to instantiate player scene")
		return
		
	add_child(player)
	camera.player = player

	# Ensure the Spawn node exists
	if not spawn:
		print("Spawn node is missing!")
		return

	# Set player's position directly at the Spawn node's position
	player.global_position = spawn.global_position

	camera.position_smoothing_enabled = true  # Enable smoothing
	camera.position_smoothing_speed = 5.0  # Adjust speed for smooth tracking
	
func on_power_up(power_type: Variant) -> void:
	if player:
		player.on_power_up_collected(power_type)

func _on_dining_threshold_entered(body):
	if body == player:
		await wait_until_grounded()  # Ensure player is stable before continuing
		update_camera_bounds()  # Update camera dynamically instead of moving
		move_player_slowly()
		ambient_noise.on_dining()
		darkness.set_color(Color("868686"))

func wait_until_grounded():
	var timeout = 5.0  # 5 second timeout
	var start_time = Time.get_ticks_msec()
	
	while not player.is_on_floor():  
		if Time.get_ticks_msec() - start_time > timeout * 1000:
			print("Player failed to ground within timeout period")
			break
		await get_tree().process_frame  

func update_camera_bounds():
	if not dining_threshold:
		print("Dining threshold is null!")
		return

	# Lock camera's left side at dining_threshold's position
	camera.limit_left = dining_threshold.global_position.x  
	# Effectively remove limits in all other directions
	camera.limit_right = 999999  # Allow movement to the right indefinitely
	camera.limit_top = -999999   # No limit upwards
	camera.limit_bottom = 999999  # No limit downwards

	# Optional: Adjust camera offset if necessary
	camera.offset = Vector2(0, -100)
	
func move_player_slowly():
	if player:
		player.set_can_move(false)
		moving_player = true
	else:
		print("Attempted to move non-existent player")

func drop_wall():
	if wall_fall:
		wall_fall.play("wall")
		await wall_fall.animation_finished  # Wait until the animation finishes
		if player:
			player.set_can_move(true)  # Allow player movement after animation ends
	else:
		print("Wall fall animation node is missing!")
	
func load_next_scene(index):
	if index >= scenes_to_load.size():
		return  # All scenes loaded

	var path = scenes_to_load[index]
	print("Loading: ", path)
	ResourceLoader.load_threaded_request(path)

	await get_tree().create_timer(0.1).timeout  # Small delay to avoid frame drops

	check_loading_progress(index)

func check_loading_progress(index):
	var path = scenes_to_load[index]
	var status = ResourceLoader.load_threaded_get_status(path)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene_resource = ResourceLoader.load_threaded_get(path)
		if scene_resource:
			var new_scene = scene_resource.instantiate()
			attach_scene(new_scene)
			loaded_scenes[path] = new_scene
			print("Loaded and attached: ", path)
		
		# Load the next scene
		load_next_scene(index + 1)
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout
		check_loading_progress(index)
		
func attach_scene(new_scene):
	# Ensure the world scene has an "Attach" node
	var world_attach = $Attach  # Assuming the world scene has this node

	# If this is the first scene, position it at the world's attach node
	if loaded_scenes.size() == 0:
		new_scene.global_position = world_attach.global_position
	else:
		# Get the last attached scene
		var last_scene = loaded_scenes.values()[-1]

		# Find attach points
		var last_attach_right = last_scene.get_node_or_null("AttachRight")
		var new_attach_left = new_scene.get_node_or_null("AttachLeft")

		if last_attach_right and new_attach_left:
			# Directly set the new scene's global position at last_attach_right
			var offset = last_attach_right.global_position - new_attach_left.global_position
			new_scene.global_position += offset  # Adjust scene position correctly
		else:
			print("Attach nodes missing in scenes!")

	# Add the new scene to the world
	add_child(new_scene)

	# Debugginga
	debug_attach_nodes(new_scene)
	
func debug_attach_nodes(scene):
	var attach_left = scene.get_node_or_null("AttachLeft")
	var attach_right = scene.get_node_or_null("AttachRight")

	if attach_left and attach_right:
		print(scene.name, " AttachLeft: ", attach_left.global_position, " AttachRight: ", attach_right.global_position)
	else:
		print(scene.name, " is missing an Attach node!")
