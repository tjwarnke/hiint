extends Control

var settings_scene = preload("res://scenes/settings_menu.tscn")
var settings_instance = null
var darkness_node = null

func _ready():
	# Set the pause menu to be on top of everything
	top_level = true
	z_index = 100  # Ensure it's above other UI elements
	
	# Hide the pause menu initially
	hide()
	
	# Find the darkness node (CanvasModulate) in the world
	var world = get_tree().get_root().get_node_or_null("World")
	if world:
		darkness_node = world.darkness
	
	# Connect button signals
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/QuitToMenuButton.pressed.connect(_on_quit_to_menu_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/QuitToDesktopButton.pressed.connect(_on_quit_to_desktop_pressed)
	
	# Enable settings button
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/SettingsButton.disabled = false
	# Disable save button for now
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/SaveButton.disabled = true
	
	# Fix scaling issue to ensure menu covers the entire screen
	# Reset negative offsets
	offset_right = 0
	offset_bottom = 0
	# Set scale to 1 first
	scale = Vector2(1, 1)
	# Make Control cover full viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Get the actual window size
	var window_size = DisplayServer.window_get_size()
	# Apply the size directly to fix scaling issues
	size = window_size

func _process(delta):
	# Ensure the menu fits the window even if resized
	if visible:
		var window_size = DisplayServer.window_get_size()
		size = window_size

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):  # Escape key by default
		if visible:
			if settings_instance and settings_instance.visible:
				# If settings menu is visible, hide it
				settings_instance.hide()
				enable_all_buttons()
				get_viewport().set_input_as_handled()  # Prevent the event from propagating
			else:
				_on_resume_pressed()
				get_viewport().set_input_as_handled()  # Prevent the event from propagating
		else:
			get_tree().paused = true
			show()
			# Force update size and position when shown
			scale = Vector2(1, 1)
			offset_right = 0
			offset_bottom = 0
			size = DisplayServer.window_get_size()
			# Hide darkness when the pause menu is shown
			toggle_darkness(false)
			get_viewport().set_input_as_handled()  # Prevent the event from propagating

func disable_all_buttons():
	# Disable all buttons in the buttons container to prevent interaction
	for button in $CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer.get_children():
		if button is Button:
			button.disabled = true

func enable_all_buttons():
	# Re-enable all buttons except the Save button (which is disabled by default)
	for button in $CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer.get_children():
		if button is Button and button != $CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/SaveButton:
			button.disabled = false

func _on_resume_pressed():
	get_tree().paused = false
	hide()
	# Show darkness when the pause menu is hidden
	toggle_darkness(true)

func _on_settings_pressed():
	# Disable all pause menu buttons
	disable_all_buttons()
	
	# First check if there's already a settings menu in the scene tree
	var existing_settings = get_tree().root.get_node_or_null("SettingsMenu")
	
	if existing_settings:
		settings_instance = existing_settings
		settings_instance.set_position_in_center(true)
		# Ensure settings appears above pause menu
		settings_instance.z_index = z_index + 10
		settings_instance.show()
		return
	
	if not settings_instance:
		settings_instance = settings_scene.instantiate()
		settings_instance.name = "SettingsMenu"  # Give it a consistent name
		# Ensure settings are positioned correctly for in-game context
		settings_instance.set_position_in_center(true)
		get_tree().root.add_child(settings_instance)
		# Ensure settings appears above pause menu
		settings_instance.z_index = z_index + 10
		settings_instance.settings_closed.connect(_on_settings_closed)
		
		# Make sure game stays paused when settings are open
		settings_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	else:
		settings_instance.set_position_in_center(true)
		# Ensure settings appears above pause menu
		settings_instance.z_index = z_index + 10
		settings_instance.show()

func _on_settings_closed():
	# Settings were closed
	if settings_instance:
		settings_instance.hide()
		# Re-enable pause menu buttons
		enable_all_buttons()

func _on_quit_to_menu_pressed():
	get_tree().paused = false
	queue_free()  # Remove the pause menu before changing scenes
	get_tree().change_scene_to_file("res://scenes/startMenu.tscn")

func _on_quit_to_desktop_pressed():
	queue_free()  # Remove the pause menu before quitting
	get_tree().quit() 

func toggle_darkness(show_darkness):
	if darkness_node:
		darkness_node.visible = show_darkness 
