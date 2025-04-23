extends Control

signal resume_game

var settings_scene = preload("res://scenes/settings_menu.tscn")
var settings_instance = null
var darkness_node = null
var game_camera = null
# Scale factors for menu elements
var panel_scale_factor = 1.3  # Scale factor for the pause menu panel
var settings_scale_factor = 3  # Scale factor for the settings menu
var stored_darkness_color = null  # Add this at the top with other variables

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
		game_camera = world.camera  # Get the camera reference
	
	# Connect button signals
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/QuitToMenuButton.pressed.connect(_on_quit_to_menu_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/QuitToDesktopButton.pressed.connect(_on_quit_to_desktop_pressed)
	
	# Enable settings button
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/SettingsButton.disabled = false
	# Disable save button for now
	$CenterContainer/PanelContainer/VBoxContainer/ButtonsContainer/SaveButton.disabled = true
	
	# Make this control a direct child of the root viewport to ensure fullscreen
	if get_parent() != get_tree().root:
		var parent = get_parent()
		parent.remove_child(self)
		get_tree().root.add_child(self)
	
	# Apply camera-based setup
	apply_camera_based_setup()

func apply_camera_based_setup():
	if not game_camera:
		# Fallback to standard positioning method
		set_proper_positioning()
		return
	
	# Calculate the camera's view size
	var camera_size = get_camera_view_size()
	
	# Reset transform and scaling
	position = Vector2.ZERO
	scale = Vector2.ONE
	rotation = 0
	
	# Set the anchors to full rect
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Set the size using deferred call to avoid anchor warnings
	call_deferred("set_size", camera_size)
	call_deferred("set_custom_minimum_size", camera_size)
	
	# Center the pause menu on camera's position
	call_deferred("set_global_position", get_camera_screen_center() - (camera_size / 2))
	
	# Adjust panel scale based on camera zoom
	var zoom_adjustment = 1.0
	if game_camera and game_camera.has_method("get_zoom"):
		var camera_zoom = game_camera.zoom
		# If in library (zoomed in), make the UI elements slightly smaller
		if camera_zoom.x < 0.8:  # Library has zoom of 0.6
			zoom_adjustment = 0.8
		else:
			zoom_adjustment = 1.0
	
	# Make sure color rect covers the full area
	if has_node("ColorRect"):
		var color_rect = $ColorRect
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		call_deferred("_set_color_rect_size", camera_size)
	
	# Make sure CenterContainer covers the full area
	if has_node("CenterContainer"):
		var center = $CenterContainer
		center.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		call_deferred("_set_center_container_size", camera_size)
	
	# Scale up the panel container and buttons
	if has_node("CenterContainer/PanelContainer"):
		var panel = $CenterContainer/PanelContainer
		panel.scale = Vector2(panel_scale_factor * zoom_adjustment, panel_scale_factor * zoom_adjustment)
		
		# Make sure all buttons are bigger
		if panel.has_node("VBoxContainer/ButtonsContainer"):
			var buttons_container = panel.get_node("VBoxContainer/ButtonsContainer")
			for button in buttons_container.get_children():
				if button is Button:
					# Increase font size for buttons
					if button.get("theme_override_font_sizes/font_size"):
						button.set("theme_override_font_sizes/font_size", int(button.get("theme_override_font_sizes/font_size") * panel_scale_factor * zoom_adjustment))
					
					# Increase button's custom minimum size
					if button.custom_minimum_size != Vector2.ZERO:
						button.custom_minimum_size *= panel_scale_factor * zoom_adjustment

# Helper methods for deferred calls
func _set_color_rect_size():
	if has_node("ColorRect"):
		$ColorRect.size = size

func _set_center_container_size():
	if has_node("CenterContainer"):
		$CenterContainer.size = size

func get_camera_view_size():
	if not game_camera:
		return get_viewport_rect().size
	
	# Calculate the camera's view size based on viewport and zoom
	var viewport_size = get_viewport_rect().size
	var camera_zoom = game_camera.zoom
	return viewport_size / camera_zoom

func get_camera_screen_center():
	if not game_camera:
		return get_viewport_rect().size / 2
	
	return game_camera.get_screen_center_position()

# Proper positioning function implementation
func set_proper_positioning():
	var viewport_size = get_viewport_rect().size
	
	# Set anchors to fill the screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	size = viewport_size
	
	# Make background fully cover screen
	if has_node("ColorRect"):
		$ColorRect.set_anchors_preset(Control.PRESET_FULL_RECT)
		$ColorRect.anchor_right = 1.0
		$ColorRect.anchor_bottom = 1.0
		$ColorRect.offset_left = 0
		$ColorRect.offset_top = 0
		$ColorRect.offset_right = 0
		$ColorRect.offset_bottom = 0
		$ColorRect.size = viewport_size
	
	# Set CenterContainer to fill the screen
	if has_node("CenterContainer"):
		$CenterContainer.set_anchors_preset(Control.PRESET_FULL_RECT)
		$CenterContainer.anchor_right = 1.0
		$CenterContainer.anchor_bottom = 1.0
		$CenterContainer.offset_left = 0
		$CenterContainer.offset_top = 0
		$CenterContainer.offset_right = 0
		$CenterContainer.offset_bottom = 0
		$CenterContainer.size = viewport_size

func _process(_delta):
	# Only update if visible to avoid unnecessary processing
	if visible:
		# Keep the pause menu matching the camera view
		if game_camera:
			# Get updated camera size
			var camera_size = get_camera_view_size()
			size = camera_size
			
			# Update position to stay centered on camera
			global_position = get_camera_screen_center() - (camera_size / 2)
			
			if has_node("ColorRect"):
				$ColorRect.size = camera_size
			
			if has_node("CenterContainer"):
				$CenterContainer.size = camera_size
		else:
			# Fallback to viewport size
			var viewport_size = get_viewport_rect().size
			size = viewport_size
			
			if has_node("ColorRect"):
				$ColorRect.size = viewport_size
			
			if has_node("CenterContainer"):
				$CenterContainer.size = viewport_size

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
			# Don't pause the entire tree, just pause the game logic
			get_tree().paused = true
			show()
			# Force update size and position when shown
			apply_camera_based_setup()
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
	# Restore darkness when the pause menu is hidden
	toggle_darkness(true)
	# Emit the resume_game signal
	emit_signal("resume_game")

func _on_settings_pressed():
	if not settings_instance:
		settings_instance = settings_scene.instantiate()
		settings_instance.name = "SettingsMenu"
		get_tree().root.add_child(settings_instance)
		
		# Use camera-based positioning for in-game settings
		settings_instance.set_position_in_center(true)
		
		# Connect the settings closed signal
		settings_instance.settings_closed.connect(_on_settings_closed)
	else:
		# Update settings positioning
		settings_instance.set_position_in_center(true)
		settings_instance.show()
	
	# Disable pause menu buttons while settings are open
	disable_all_buttons()

func _on_settings_closed():
	# Re-enable pause menu buttons
	enable_all_buttons()

func _on_quit_to_menu_pressed():
	# Stop all in-game processes
	get_tree().paused = false
	
	# Transition back to start menu
	get_tree().change_scene_to_file("res://scenes/startMenu.tscn")

func _on_quit_to_desktop_pressed():
	get_tree().quit()

func toggle_darkness(visible_state):
	if darkness_node:
		if visible_state:
			# If we want darkness visible, restore the stored color or use default
			if stored_darkness_color:
				darkness_node.color = stored_darkness_color
			else:
				darkness_node.color = Color("555555")  # Default dark gray
		else:
			# Store the current color before hiding darkness
			stored_darkness_color = darkness_node.color
			darkness_node.color = Color(1, 1, 1, 1)  # White = no darkening 
