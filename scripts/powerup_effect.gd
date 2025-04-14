extends Node2D

@onready var particles = $CPUParticles2D

func _ready():
	# Start emitting as soon as created
	if particles:
		particles.emitting = true
		# Set up timer to clean up after effect is done
		var timer = get_tree().create_timer(particles.lifetime + 0.1)
		timer.timeout.connect(queue_free)
	else:
		push_error("PowerupEffect: Particles node not found!")
		queue_free()

func set_color(color: Color):
	if particles:
		particles.color = color
	else:
		push_error("PowerupEffect: Cannot set color - particles node not found!") 
