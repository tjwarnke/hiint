extends Control

const WORLD_SCENE_PATH = "res://scenes/world.tscn"

@onready var progress_bar = $ProgressBar
@onready var loading_label = $Label

# Loading states for better user feedback
const LOADING_STATES = [
	"Loading world...",
	"Preparing environment...",
	"Initializing game systems...",
	"Almost ready..."
]

var current_state_index = 0
var state_timer = 0.0
const STATE_CHANGE_TIME = 1.0  # Change state every second

# Progress animation settings
var target_progress = 0.0
var current_progress = 0.0
const PROGRESS_SPEED = 0.3  # Progress per second (30% per second)

func _ready():
	progress_bar.value = 0
	loading_label.text = LOADING_STATES[0]
	load_game_async()

func _process(delta):
	# Update loading state text periodically
	state_timer += delta
	if state_timer >= STATE_CHANGE_TIME:
		state_timer = 0.0
		current_state_index = (current_state_index + 1) % LOADING_STATES.size()
		update_loading_text()
	
	# Simple linear progress animation
	if current_progress < target_progress:
		current_progress = min(current_progress + PROGRESS_SPEED * delta, target_progress)
		progress_bar.value = current_progress * 100
		update_loading_text()

func update_loading_text():
	var progress_percent = int(progress_bar.value)
	loading_label.text = "%s... %d%%" % [LOADING_STATES[current_state_index], progress_percent]

func load_game_async():
	var progress = []
	ResourceLoader.load_threaded_request(WORLD_SCENE_PATH)

	while true:
		var status = ResourceLoader.load_threaded_get_status(WORLD_SCENE_PATH, progress)
		
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Update target progress
			target_progress = progress[0] if progress else 0.0
			
			# If we're stuck at 50%, force progress forward
			if target_progress < 0.5 and current_progress >= 0.5:
				target_progress = 0.5
			
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			# Ensure we show 100% before transitioning
			target_progress = 1.0
			await get_tree().create_timer(0.5).timeout
			
			# Change to the loaded scene
			var loaded_scene = ResourceLoader.load_threaded_get(WORLD_SCENE_PATH)
			get_tree().change_scene_to_packed(loaded_scene)
			break
			
		else:
			push_error("Failed to load scene: %s" % WORLD_SCENE_PATH)
			loading_label.text = "Error: Failed to load game. Please try again."
			break

		await get_tree().process_frame
