extends Node

@export var min_creepy_interval: float = 5.0  # Minimum time between creepy sounds
@export var max_creepy_interval: float = 15.0 # Maximum time between creepy sounds

var random_sounds = []
var rng = RandomNumberGenerator.new()
var delay = rng.randf_range(min_creepy_interval, max_creepy_interval)
var timer = Timer.new()

func _ready():
	# Get references to sounds
	var rain = $Rain
	var birds = $Birds
	var wind = $Wind

	random_sounds = [$Shing, $Woosh, $Boom]
	for item in random_sounds:
		item.volume_db += 5

	# Start looping ambient sounds
	if rain:
		rain.volume_db += 2
		rain.play()
	if birds:
		birds.volume_db -= 17  # Lower the volume of birds
		birds.play()
		apply_random_variation(birds)
	if wind:
		wind.play()
		apply_random_variation(wind)

	# Schedule first random creepy sound
	schedule_creepy_sound()

func apply_random_variation(sound):
	sound.pitch_scale = rng.randf_range(0, 2)  # Slightly vary pitch


	timer.wait_time = rng.randf_range(3, 7)  # Change variation every 3-7 seconds
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(func():
		apply_random_variation(sound)
	)
	add_child(timer)

func schedule_creepy_sound():
	timer.wait_time = delay
	timer.one_shot = true
	timer.timeout.connect(func():
		play_random_creepy_sound()
		schedule_creepy_sound()  # Schedule next sound
	)
	add_child(timer)
	timer.start()

func play_random_creepy_sound():
	var sound = random_sounds[rng.randi_range(0, random_sounds.size() - 1)]
	sound.pitch_scale = rng.randf_range(0.9, 1.1)  # Slight variation
	sound.play()
