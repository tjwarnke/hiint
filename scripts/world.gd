extends Node2D

# Load player scene
var PlayerScene = preload("res://scenes/Player.tscn")  
var player

# Scene paths
const DINING_ROOM_PATH = "res://scenes/dining_room.tscn"
const LIBRARY_PATH = "res://scenes/Library.tscn"
const BILLIARDS_ROOM_PATH = "res://scenes/billiards_room.tscn"
const DUNGEON_PATH = "res://scenes/dungeon.tscn"
const TUTORIAL_PATH = "res://scenes/second_tutorial.tscn"

# Nodes
@onready var spawn = get_node_or_null("Spawn")
@onready var camera = $Camera2D  
@onready var jumpscare = $Camera2D/Jumpscare
@onready var jumpscare_timer = $Camera2D/Timer  
@onready var jumpscare_noise = $Camera2D/AudioStreamPlayer
@onready var darkness = $Camera2D/CanvasModulate
@onready var ambient_noise = preload("res://scenes/ambient_noise.tscn").instantiate()
@onready var world_attach_node = $Attach  # Rename to clarify this is the world's attach node

# Dining room nodes (will be set after scene is loaded)
var dining_wall = null
var dining_threshold = null
var wall_fall = null

var scenes_to_load = [
	"res://scenes/second_tutorial.tscn",
	"res://scenes/dining_room.tscn",
	"res://scenes/library.tscn",
	"res://scenes/billiards_room.tscn",
	"res://scenes/dungeon.tscn"
]

var loaded_scenes = {}
var current_attach_node = null  # Track the current attach node for the next scene

var moving_player = false
var move_distance = 500
var move_speed = 100.0
var camera_smooth_speed = 0.0001  # Adjust this value for smoother/slower movement

var loading_thread: Thread
var mutex: Mutex

func _ready():
	spawn_player()
	initialize_game_state()
	call_deferred("set_camera_target")
	# Start background loading immediately
	mutex = Mutex.new()
	loading_thread = Thread.new()
	loading_thread.start(Callable(self, "load_scenes_in_background"))

func _process(delta):
	# Handle input
	handle_input()
	
	# Handle player movement
	handle_player_movement(delta)

func set_camera_target():
	if player:
		camera.player = player
	else:
		push_error("Player is missing when setting camera target!")
		
func initialize_game_state():
	darkness.show()
	$cabin/Torch.show()
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


func show_jumpscare():
	jumpscare.show()
	jumpscare_timer.start()

func hide_jumpscare():
	jumpscare.hide()

	
func spawn_player():
	player = PlayerScene.instantiate()
	if not player:
		push_error("Failed to instantiate player scene")
		return

	add_child(player)

	# Ensure spawn exists before setting position
	if not spawn:
		push_error("Spawn node is missing!")
		return
	player.global_position = spawn.global_position

	# Set up the camera
	camera.player = player
	camera.position = Vector2(player.position.x, camera.fixed_y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.drag_horizontal_enabled = true
	camera.drag_left_margin = 0.1
	camera.drag_top_margin = 0.1
	camera.drag_right_margin = 0.1
	camera.drag_bottom_margin = 0.1
	
func initialize_camera():
	camera.position = Vector2(player.position.x, camera.fixed_y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.drag_horizontal_enabled = true
	camera.drag_left_margin = 0.1
	camera.drag_top_margin = 0.1
	camera.drag_right_margin = 0.1
	camera.drag_bottom_margin = 0.1
	
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
	
func load_scenes_in_background():
	# Load first scene
	load_first_scene()
	
	# Load remaining scenes in sequence
	for i in range(1, scenes_to_load.size()):
		load_next_scene(i)

func load_first_scene():
	if not world_attach_node:
		push_error("World attach node is missing!")
		return
		
	var first_scene_path = scenes_to_load[0]
	var first_scene = load(first_scene_path)
	if not first_scene:
		push_error("Failed to load scene: " + first_scene_path)
		return
		
	var instance = first_scene.instantiate()
	if not instance:
		push_error("Failed to instantiate scene: " + first_scene_path)
		return
		
	# Scale the scene first
	instance.scale = Vector2(0.5, 0.5)
		
	# Find the AttachLeft node in the instantiated scene
	var attach_left = instance.get_node_or_null("AttachLeft")
	if not attach_left:
		push_error("AttachLeft node not found in scene: " + first_scene_path)
		return
		
	# Position the scene so AttachLeft aligns with the world's Attach node
	instance.global_position = world_attach_node.global_position - attach_left.global_position
	
	# Add the scene as a child
	call_deferred("add_child", instance)
	
	# Store the loaded scene and update the current attach node
	mutex.lock()
	loaded_scenes[first_scene_path] = instance
	mutex.unlock()
	
	# Set the current attach node for the next scene
	current_attach_node = instance.get_node_or_null("Attach")
	if not current_attach_node:
		push_error("Attach node not found in first scene: " + first_scene_path)
		return
	
	print("Loaded first scene: ", first_scene_path)  # Debug print

func load_next_scene(index: int):
	if not current_attach_node:
		push_error("Current attach node is missing!")
		return
		
	var scene_path = scenes_to_load[index]
	var scene = load(scene_path)
	if not scene:
		push_error("Failed to load scene: " + scene_path)
		return
		
	var instance = scene.instantiate()
	if not instance:
		push_error("Failed to instantiate scene: " + scene_path)
		return
		
	# Scale the scene first
	instance.scale = Vector2(0.5, 0.5)
		
	# Find the AttachLeft node in the instantiated scene
	var attach_left = instance.get_node_or_null("AttachLeft")
	if not attach_left:
		push_error("AttachLeft node not found in scene: " + scene_path)
		return
		
	# Position the scene so AttachLeft aligns with the previous scene's Attach node
	instance.global_position = current_attach_node.global_position - attach_left.global_position
	
	# Add the scene as a child
	call_deferred("add_child", instance)
	
	# Store the loaded scene
	mutex.lock()
	loaded_scenes[scene_path] = instance
	mutex.unlock()
	
	# Update the current attach node for the next scene
	current_attach_node = instance.get_node_or_null("Attach")
	if not current_attach_node:
		push_error("Attach node not found in loaded scene: " + scene_path)
		return
	
	print("Loaded scene: ", scene_path)  # Debug print

func _exit_tree():
	if loading_thread and loading_thread.is_started():
		loading_thread.wait_to_finish()
