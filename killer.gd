extends Node2D

var is_moving = false
var speed = 500

func _ready():
	$MoveTimer.connect("timeout", Callable(self, "_on_move_timer_timeout"))

func _process(delta):
	if is_moving:
		position.x += speed * delta

func start_moving():
	is_moving = true
	$MoveSound.play()
	$MoveTimer.start()

func _on_move_timer_timeout():
	queue_free()
