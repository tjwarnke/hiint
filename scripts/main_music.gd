extends AudioStreamPlayer

# Static reference to the single instance of this player
static var instance = null

# Additional audio players for persistent sounds
var rain_player = null
var ambient_player = null
var spooky_player = null

# Preload sound resources
const RAIN_SOUND = preload("res://assets/audio/rain.mp3")
const AMBIENT_SOUND = preload("res://assets/audio/GameSongIntro-MP3.mp3") # Replace with actual ambient

# Keep track of original volumes for restore functionality
var original_volumes = {
	"music": -5.0,  # Set a reasonable starting volume (not too loud)
	"rain": -5.0,
	"ambient": -10.0,
	"spooky": -15.0
}

func _ready():
	# Check for existing instance using the singleton pattern
	if instance != null:
		# Print debug message to verify the check is working
		print("Music singleton detected, removing duplicate")
		# Another music player already exists, remove this duplicate immediately
		queue_free()
		return
	
	# Print debug message to verify a new instance is being created
	print("Creating music singleton instance")
	
	# First instance - become the singleton
	instance = self
	
	# Ensure this node persists between scenes
	process_mode = PROCESS_MODE_ALWAYS
	
	# Set the audio bus to Music for volume control
	bus = "Music"
	
	# Set initial volume (not max)
	volume_db = original_volumes["music"]
	
	# Create additional audio players for ambient sounds that persist across scenes
	setup_persistent_audio()
	
	# Make this node persist when changing scenes
	get_tree().set_auto_accept_quit(false)
	
	# Move to root to persist across scene changes if needed
	if get_parent() != get_tree().root:
		var parent = get_parent()
		parent.remove_child(self)
		get_tree().root.add_child(self)
	
	# Start playing music (only once the singleton is established)
	if not playing:
		play()
		print("Started playing music on singleton instance")

# Set up additional persistent audio players
func setup_persistent_audio():
	# Rain sound
	rain_player = AudioStreamPlayer.new()
	rain_player.stream = RAIN_SOUND
	rain_player.volume_db = original_volumes["rain"]
	rain_player.bus = "Ambient"
	rain_player.autoplay = true
	add_child(rain_player)
	
	# Ambient sounds
	ambient_player = AudioStreamPlayer.new()
	ambient_player.stream = AMBIENT_SOUND
	ambient_player.volume_db = original_volumes["ambient"]
	ambient_player.bus = "Ambient"
	ambient_player.autoplay = true
	add_child(ambient_player)
	
	# Spooky sounds (to be added based on game state)
	spooky_player = AudioStreamPlayer.new()
	spooky_player.bus = "Spooky"
	spooky_player.volume_db = original_volumes["spooky"]
	add_child(spooky_player)

# Fade out only the music while keeping ambient sounds
func fade_out_music_only(duration: float = 5.0):
	if playing:
		# Store the original volume to restore it later if needed
		original_volumes["music"] = volume_db
		
		var tween = create_tween()
		tween.tween_property(self, "volume_db", -40, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		# Don't stop - just reduce volume significantly but keep it playing
		# Don't need to call stop()
		print("Music faded down but still playing at low volume")
		
# Restore music to original volume
func restore_music_volume(duration: float = 3.0):
	var target_vol = original_volumes["music"]
	print("Restoring music volume to: ", target_vol)
	
	# Only create a tween if the current volume is different
	if volume_db < target_vol - 1.0:
		var tween = create_tween()
		tween.tween_property(self, "volume_db", target_vol, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
		print("Music volume restored")
		
# Generic fade out function for any audio player
func fade_out(audio_player: AudioStreamPlayer, duration: float = 2.0):
	if audio_player and audio_player.playing:
		var tween = create_tween()
		tween.tween_property(audio_player, "volume_db", -80, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		audio_player.stop()

# Mute/unmute ambient sounds without stopping them
func set_ambient_enabled(enabled: bool):
	if rain_player:
		rain_player.volume_db = original_volumes["rain"] if enabled else -80.0
	if ambient_player:
		ambient_player.volume_db = original_volumes["ambient"] if enabled else -80.0

# Reset the singleton when this node is deleted
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Reset the static reference when this node is being deleted
		if instance == self:
			print("Music singleton instance destroyed")
			instance = null
