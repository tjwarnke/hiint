extends Node

# Audio players for ambient sound
var cabin_sound: AudioStreamPlayer
var dining_sound: AudioStreamPlayer
var library_sound: AudioStreamPlayer
var billiards_sound: AudioStreamPlayer

# Creepy sound effects
var random_sounds = []
var timer: Timer
var delay = 15.0  # Time between random sounds
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	setup_ambient_sounds()
	setup_random_sounds()
	timer = Timer.new()
	schedule_creepy_sound()

func setup_ambient_sounds():
	# Cabin ambience
	cabin_sound = AudioStreamPlayer.new()
	cabin_sound.stream = preload("res://assets/audio/rain.mp3")
	cabin_sound.volume_db = -15.0  # Start with quieter ambient sound
	cabin_sound.bus = "Ambient"
	add_child(cabin_sound)
	cabin_sound.play()
	
	# Dining ambience
	dining_sound = AudioStreamPlayer.new()
	dining_sound.stream = preload("res://assets/audio/GameSongIntro-MP3.mp3")
	dining_sound.volume_db = -80  # Start silent
	dining_sound.bus = "Ambient"
	add_child(dining_sound)
	
	# Library ambience (add appropriate sound file)
	library_sound = AudioStreamPlayer.new()
	library_sound.stream = preload("res://assets/audio/GameSongIntro-MP3.mp3")
	library_sound.volume_db = -80  # Start silent
	library_sound.bus = "Ambient"
	add_child(library_sound)
	
	# Billiards ambience (add appropriate sound file)
	billiards_sound = AudioStreamPlayer.new()
	billiards_sound.stream = preload("res://assets/audio/GameSongIntro-MP3.mp3")
	billiards_sound.volume_db = -80  # Start silent
	billiards_sound.bus = "Ambient"
	add_child(billiards_sound)

func setup_random_sounds():
	# Add creepy sound effects
	var sound_files = [
		"res://assets/audio/rain.mp3",  # Replace with actual creepy sounds
		"res://assets/audio/GameSongIntro-MP3.mp3"
	]
	
	for file in sound_files:
		var player = AudioStreamPlayer.new()
		player.stream = load(file)
		player.volume_db = -10.0
		player.bus = "Spooky"
		add_child(player)
		random_sounds.append(player)

func schedule_creepy_sound():
	timer.wait_time = delay
	timer.one_shot = true
	
	# Ensure we don't re-add the timer if it already exists in the scene
	if not timer.get_parent():
		add_child(timer)
	
	timer.timeout.connect(func():
		play_random_creepy_sound()
		schedule_creepy_sound()  # Schedule next sound
	)
	
	timer.start()

func play_random_creepy_sound():
	var sound = random_sounds[rng.randi_range(0, random_sounds.size() - 1)]
	sound.pitch_scale = rng.randf_range(0.9, 1.1)  # Slight variation
	sound.play()

func fade_in(audio_player: AudioStreamPlayer, duration: float = 2.0, target_volume: float = -10.0):
	if audio_player:
		var tween = create_tween()
		tween.tween_property(audio_player, "volume_db", target_volume, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func fade_out(audio_player: AudioStreamPlayer, duration: float = 2.0):
	if audio_player:
		var tween = create_tween()
		tween.tween_property(audio_player, "volume_db", -80, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): 
			audio_player.stop()
		)

func on_dining():
	# Fade out outdoor sounds when entering the mansion
	fade_out_outdoor_sounds(3.0)
	
	# Fade out cabin sound and fade in dining sound
	fade_out(cabin_sound, 3.0)
	dining_sound.play()
	fade_in(dining_sound, 3.0)

# New function to fade out outdoor sounds (birds and wind)
func fade_out_outdoor_sounds(duration: float = 3.0):
	# Find the birds and wind audio players
	var birds_player = get_node_or_null("Birds")
	var wind_player = get_node_or_null("Wind")
	
	if birds_player:
		fade_out(birds_player, duration)
	
	if wind_player:
		fade_out(wind_player, duration)

func on_library():
	fade_out(cabin_sound, 3.0)
	fade_out(dining_sound, 3.0)
	library_sound.play()
	fade_in(library_sound, 3.0)

func on_billiards():
	fade_out(cabin_sound, 3.0)
	fade_out(dining_sound, 3.0)
	fade_out(library_sound, 3.0)
	billiards_sound.play()
	fade_in(billiards_sound, 3.0)

func set_volume_level(volume_db):
	# Set volume for all ambient sounds
	for sound in [cabin_sound, dining_sound, library_sound, billiards_sound]:
		if sound:
			sound.volume_db = volume_db 

func stop_audio_player(audio_player: AudioStreamPlayer) -> void:
	if audio_player and audio_player.playing:
		audio_player.stop() 
