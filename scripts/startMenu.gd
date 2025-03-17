
extends Control

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton

func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_quit_button_pressed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()

func _on_start_button_pressed():
	# Just load the loading screen — let it handle the main scene loading
	get_tree().change_scene_to_file("res://scenes/loadingScreen.tscn")
