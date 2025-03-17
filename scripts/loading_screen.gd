extends Control

const WORLD_SCENE_PATH = "res://scenes/world.tscn"

@onready var progress_bar = $ProgressBar
@onready var loading_label = $Label

func _ready():
	progress_bar.value = 0  # Ensure progress starts at 0
	loading_label.text = "Loading... 0%"
	load_game_async()

func load_game_async():
	var progress = []
	ResourceLoader.load_threaded_request(WORLD_SCENE_PATH)

	while true:
		var status = ResourceLoader.load_threaded_get_status(WORLD_SCENE_PATH, progress)

		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var progress_percent = int((progress[0] if progress else 0) * 100)
			progress_bar.value = progress_percent
			loading_label.text = "Loading... %d%%" % progress_percent
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			var loaded_scene = ResourceLoader.load_threaded_get(WORLD_SCENE_PATH)
			get_tree().change_scene_to_packed(loaded_scene)
			break
		else:
			push_error("Failed to load scene: %s" % WORLD_SCENE_PATH)
			break

		await get_tree().process_frame  # Ensure updates every frame
