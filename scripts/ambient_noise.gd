extends Node

@export var min_creepy_interval: float = 10.0  # Minimum time between creepy sounds
@export var max_creepy_interval: float = 30.0 # Maximum time between creepy sounds

var random_sounds = []
var rng = RandomNumberGenerator.new()
var delay = rng.randf_range(min_creepy_interval, max_creepy_interval)
var timer = Timer.new()

@onready var music = $BackgroundMusic
@onready var rain = $Rain
@onready var birds = $Birds
@onready var wind = $Wind
@onready var shing = $Shing
@onready var woosh = $Woosh
@onready var boom = $Boom

func _ready():
	random_sounds = [shing, woosh, boom]

	# Set audio buses for proper volume control
	music.bus = "Music"
	
	# Ambient sounds
	rain.bus = "Ambient"
	birds.bus = "Ambient"
	wind.bus = "Ambient"
	
	# Spooky sounds
	shing.bus = "Spooky"
	woosh.bus = "Spooky"
	boom.bus = "Spooky"

	# Schedule first random creepy sound
	schedule_creepy_sound()

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

func fade_in(audio_player: AudioStreamPlayer, duration: float = 20.0, target_volume: float = -6.0):
	if audio_player:
		var tween = create_tween()
		tween.tween_property(audio_player, "volume_db", target_volume, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func fade_out(audio_player: AudioStreamPlayer, duration: float = 30.0):
	if audio_player:
		var tween = create_tween()
		tween.tween_property(audio_player, "volume_db", -80, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): 
			audio_player.stop()
		)

func on_dining():
	music.volume_db = -80  # Start from silence
	music.play()
	fade_in(music, 5)
	fade_out(rain, 10)
	fade_out(birds, 10)
	fade_out(wind, 10)
	boom.play()
	
