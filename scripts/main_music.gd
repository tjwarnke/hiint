extends Node

# Static reference to the single instance of this player
static var instance = null

# Audio player reference
@onready var music_player = $MusicPlayer

# Additional audio players for persistent sounds
var rain_player = null
var ambient_player = null
var spooky_player = null

# Preload sound resources
const RAIN_SOUND = preload("res://assets/audio/rain.mp3")
const AMBIENT_SOUND = preload("res://assets/audio/GameSongIntro-MP3.mp3")
const MENU_MUSIC = preload("res://assets/audio/Intro.mp3")
const LEVEL_MUSIC = preload("res://assets/audio/game_level.mp3")

# Keep track of original volumes for restore functionality
var original_volumes = {
	"music": -5.0,  # Set a reasonable starting volume (not too loud)
	"rain": -5.0,
	"ambient": -10.0,
	"spooky": -15.0
}

func _ready():
	# Check if another instance exists
	if instance != null and instance != self:
		queue_free()
		return
		
	instance = self
	
	# Set up the audio player
	music_player.bus = "Music"
	
	# Set initial volume
	music_player.volume_db = original_volumes["music"]
	
	# Load and play the menu music by default
	music_player.stream = MENU_MUSIC
	music_player.play()
	
	# Ensure the music player is not muted
	music_player.volume_db = original_volumes["music"]
	
	# Connect to the tree_exiting signal to handle cleanup
	tree_exiting.connect(_on_tree_exiting)

func _on_tree_exiting():
	# Clean up when the scene is being removed
	if instance == self:
		instance = null

# Set up additional persistent audio players
func setup_persistent_audio():
	# Rain sound
	rain_player = AudioStreamPlayer.new()
	rain_player.stream = RAIN_SOUND
	rain_player.bus = "Ambient"
	rain_player.volume_db = original_volumes["rain"]
	add_child(rain_player)
	
	# Ambient sound
	ambient_player = AudioStreamPlayer.new()
	ambient_player.stream = AMBIENT_SOUND
	ambient_player.bus = "Ambient"
	ambient_player.volume_db = original_volumes["ambient"]
	add_child(ambient_player)
	
	# Spooky sound
	spooky_player = AudioStreamPlayer.new()
	spooky_player.stream = AMBIENT_SOUND  # Using ambient sound for spooky
	spooky_player.bus = "Ambient"
	spooky_player.volume_db = original_volumes["spooky"]
	add_child(spooky_player)

# Function to transition to menu music
func transition_to_menu_music():
	if music_player:
		music_player.stream = MENU_MUSIC
		music_player.volume_db = original_volumes["music"]
		music_player.play()

# Function to transition to level music
func transition_to_level_music():
	if music_player:
		music_player.stream = LEVEL_MUSIC
		music_player.volume_db = original_volumes["music"]
		music_player.play()

# Function to fade out music
func fade_out_music_only(duration: float = 2.0):
	if music_player:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, duration)
		tween.tween_callback(music_player.stop)

# Function to restore music volume
func restore_music_volume():
	if music_player:
		music_player.volume_db = original_volumes["music"]

# Function to mute/unmute ambient sounds
func set_ambient_muted(muted: bool):
	if rain_player:
		rain_player.volume_db = -80.0 if muted else original_volumes["rain"]
	if ambient_player:
		ambient_player.volume_db = -80.0 if muted else original_volumes["ambient"]
	if spooky_player:
		spooky_player.volume_db = -80.0 if muted else original_volumes["spooky"]

func stop_ambient_sounds():
	var ambient = get_node_or_null("/root/World/ambient_noise")
	if ambient:
		ambient.stop_all_sounds()

func _exit_tree():
	instance = null
