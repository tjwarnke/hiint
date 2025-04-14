extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton

var settings_scene = preload("res://scenes/settings_menu.tscn")
var settings_instance = null

func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_quit_button_pressed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _on_start_button_pressed():
	# Just load the loading screen — let it handle the main scene loading
	get_tree().change_scene_to_file("res://scenes/loadingScreen.tscn")

func _on_settings_button_pressed():
	if not settings_instance:
		settings_instance = settings_scene.instantiate()
		settings_instance.name = "SettingsMenu"  # Give it a consistent name
		# Add to the root viewport to ensure it's positioned correctly
		get_tree().root.add_child(settings_instance)
		# Use full screen settings display (the default)
		settings_instance.set_position_in_center(false)
		settings_instance.settings_closed.connect(_on_settings_closed)
	else:
		# Use full screen settings display
		settings_instance.set_position_in_center(false)
		settings_instance.show()

func _on_settings_closed():
	# Settings were closed
	pass
