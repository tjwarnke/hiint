extends Control

const WORLD_SCENE_PATH = "res://scenes/world.tscn"

# Error handling constants
const ERROR_TIMEOUT = 60.0  # Maximum time to wait for loading
const ERROR_RETRY_COUNT = 3  # Number of times to retry loading
const ERROR_RETRY_DELAY = 1.0  # Delay between retries in seconds

@onready var progress_bar = $ProgressBar
@onready var loading_label = $Label

# Loading states for better user feedback
const LOADING_STATES = [
	"Loading Cabin...",
	"Preparing tutorial area...",
	"Initializing powerups...",
	"Making music...",
	"Choosing the killer...",
	"Almost ready..."
]

var current_state_index = 0
var state_timer = 0.0
const STATE_CHANGE_TIME = 7.0  # Change state every second

# Progress animation settings
var current_progress = 0.0
const PROGRESS_SPEED = 0.04  # Progress per second (5% per second)
var is_loading_complete = false

# Scene loading queue
var scene_queue = []
var current_scene_index = 0

# Error tracking
var error_count = 0
var loading_start_time = 0.0
var current_retry_count = 0
var last_error = ""

# Timing variables
var retry_timer = 0.0
var transition_timer = 0.0
var is_retrying = false
var is_transitioning = false

func _ready():
	progress_bar.value = 0
	loading_label.text = LOADING_STATES[0]
	loading_start_time = Time.get_ticks_msec()
	
	# Don't adjust music volume at all during loading screen
	# This keeps consistent volume from menu to level
	
	load_game_async()

func _process(delta):
	# Update loading state text periodically
	state_timer += delta
	if state_timer >= STATE_CHANGE_TIME:
		state_timer = 0.0
		current_state_index = (current_state_index + 1) % LOADING_STATES.size()
		update_loading_text()
	
	# Simple linear progress animation
	if current_progress < 0.98:  # Only progress up to 98%
		current_progress = min(current_progress + PROGRESS_SPEED * delta, 0.98)
		progress_bar.value = current_progress * 100
		update_loading_text()
	elif not is_loading_complete:
		# At 98%, check if loading is actually complete
		var status = ResourceLoader.load_threaded_get_status(WORLD_SCENE_PATH)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			is_loading_complete = true
			# Complete the progress bar
			current_progress = 1.0
			progress_bar.value = 100
			update_loading_text()
			complete_transition()
	
	# Check for timeout
	var current_time = Time.get_ticks_msec()
	if current_time - loading_start_time > ERROR_TIMEOUT * 1000:
		handle_error("Loading timeout exceeded", true)
	
	# Handle retry timing
	if is_retrying:
		retry_timer += delta
		if retry_timer >= ERROR_RETRY_DELAY:
			is_retrying = false
			retry_timer = 0.0
			load_game_async()

func update_loading_text():
	var progress_percent = int(progress_bar.value)
	loading_label.text = "%s... %d%%" % [LOADING_STATES[current_state_index], progress_percent]

func handle_error(error_message: String, is_critical: bool = false):
	error_count += 1
	last_error = error_message
	
	# Log the error with context
	var error_context = "Error %d: %s\n" % [error_count, error_message]
	error_context += "Time elapsed: %.1f seconds\n" % [(Time.get_ticks_msec() - loading_start_time) / 1000.0]
	error_context += "Current progress: %.1f%%\n" % [progress_bar.value]
	error_context += "Current state: %s\n" % [LOADING_STATES[current_state_index]]
	
	push_error(error_context)
	
	if is_critical:
		# Show error to user
		loading_label.text = "Error: %s\nRetrying..." % error_message
		
		# Attempt recovery if possible
		if current_retry_count < ERROR_RETRY_COUNT:
			current_retry_count += 1
			is_retrying = true
			retry_timer = 0.0
		else:
			# Fatal error - show error screen
			show_fatal_error(error_context)

func show_fatal_error(error_context: String):
	# Create error screen
	var error_screen = Control.new()
	error_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var error_label = Label.new()
	error_label.text = "Fatal Error\n\n%s\n\nPlease check the console for details." % error_context
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.size = get_viewport_rect().size
	error_label.position = Vector2.ZERO
	
	error_screen.add_child(error_label)
	add_child(error_screen)

func load_game_async():
	# Reset error tracking
	error_count = 0
	loading_start_time = Time.get_ticks_msec()
	
	# Validate scene paths
	if not FileAccess.file_exists(WORLD_SCENE_PATH):
		handle_error("Cabin scene file not found: %s" % WORLD_SCENE_PATH, true)
		return
	
	# Start loading
	ResourceLoader.load_threaded_request(WORLD_SCENE_PATH)

func complete_transition():
	# Change to the loaded scene
	var loaded_scene = ResourceLoader.load_threaded_get(WORLD_SCENE_PATH)
	if loaded_scene == null:
		handle_error("Failed to get loaded cabin scene", true)
		return
	
	# Don't adjust music volume here - let the world scene handle it with a timer
	
	# Change to cabin scene
	get_tree().change_scene_to_packed(loaded_scene)
