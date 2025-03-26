extends Control

const WORLD_SCENE_PATH = "res://scenes/world.tscn"
const SMOOTH_SPEED = 0.1  # Controls how quickly the progress bar catches up to actual progress

@onready var progress_bar = $ProgressBar
@onready var loading_label = $Label

var current_progress = 0.0
var target_progress = 0.0

func _ready():
	progress_bar.value = 0  # Ensure progress starts at 0
	loading_label.text = "Loading... 0%"
	load_game_async()

func _process(_delta):
	# Smoothly interpolate current progress towards target progress
	if current_progress < target_progress:
		current_progress = lerp(current_progress, target_progress, SMOOTH_SPEED)
		var progress_percent = int(current_progress * 100)
		progress_bar.value = progress_percent
		loading_label.text = "Loading... %d%%" % progress_percent

func load_game_async():
	var progress = []
	ResourceLoader.load_threaded_request(WORLD_SCENE_PATH)

	while true:
		var status = ResourceLoader.load_threaded_get_status(WORLD_SCENE_PATH, progress)

		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			target_progress = progress[0] if progress else 0
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			target_progress = 1.0  # Ensure we reach 100%
			# Wait a short moment at 100% before changing scene
			await get_tree().create_timer(0.5).timeout
			var loaded_scene = ResourceLoader.load_threaded_get(WORLD_SCENE_PATH)
			get_tree().change_scene_to_packed(loaded_scene)
			break
		else:
			push_error("Failed to load scene: %s" % WORLD_SCENE_PATH)
			break

		await get_tree().process_frame  # Ensure updates every frame
