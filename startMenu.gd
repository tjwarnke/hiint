extends Control

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton
@onready var world = get_parent()  # Reference to World node

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_start_button_pressed():
	world.start_game()  # Call the start_game function in World.gd

func _on_quit_button_pressed():
	get_tree().quit()

func _input(event):
	# Check if Enter (Return) key is pressed
	if event.is_action_pressed("ui_accept"):  
		_on_start_button_pressed()  # Start the game
