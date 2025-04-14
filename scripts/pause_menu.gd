extends Control

var settings_scene = preload("res://scenes/settings_menu.tscn")
var settings_instance = null
var darkness_node = null
var game_camera = null
# Scale factors for menu elements
var panel_scale_factor = 1.3  # Scale factor for the pause menu panel
var settings_scale_factor = 3  # Scale factor for the settings menu

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
		# Fallback to viewport if camera not found
		apply_fullscreen_setup()
		return
	
	# Calculate the camera's view size
	var camera_size = get_camera_view_size()
	
	# Reset transform and scaling
	position = Vector2.ZERO
	scale = Vector2.ONE
	rotation = 0
	
	# Set the size to match camera view
	size = camera_size
	custom_minimum_size = camera_size
	
	# Center the pause menu on camera's position
	global_position = get_camera_screen_center() - (camera_size / 2)
	
	# Make sure color rect covers the full area
	if has_node("ColorRect"):
		var color_rect = $ColorRect
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		color_rect.size = camera_size
	
	# Make sure CenterContainer covers the full area
	if has_node("CenterContainer"):
		var center = $CenterContainer
		center.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		center.size = camera_size
	
	# Scale up the panel container and buttons
	if has_node("CenterContainer/PanelContainer"):
		var panel = $CenterContainer/PanelContainer
		panel.scale = Vector2(panel_scale_factor, panel_scale_factor)
		
		# Make sure all buttons are bigger
		if panel.has_node("VBoxContainer/ButtonsContainer"):
			var buttons_container = panel.get_node("VBoxContainer/ButtonsContainer")
			for button in buttons_container.get_children():
				if button is Button:
					# Increase font size for buttons
					if button.get("theme_override_font_sizes/font_size"):
						button.set("theme_override_font_sizes/font_size", int(button.get("theme_override_font_sizes/font_size") * panel_scale_factor))
					
					# Increase button's custom minimum size
					if button.custom_minimum_size != Vector2.ZERO:
						button.custom_minimum_size *= panel_scale_factor

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

# Legacy function kept for fallback
func apply_fullscreen_setup():
	# Use viewport size rather than window size
	var viewport_size = get_viewport_rect().size
	
	# Reset transform and scaling completely
	position = Vector2.ZERO
	scale = Vector2.ONE
	rotation = 0
	
	# Reset all constraints to fill the viewport
	set_anchors_preset(Control.PRESET_FULL_RECT, true) # true = keep margins
	
	# Explicitly set the full rect positioning
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	
	# Set explicit size to match viewport
	size = viewport_size
	custom_minimum_size = viewport_size
	
	# Make sure color rect covers the full area
	if has_node("ColorRect"):
		var color_rect = $ColorRect
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		color_rect.anchor_left = 0
		color_rect.anchor_top = 0
		color_rect.anchor_right = 1
		color_rect.anchor_bottom = 1
		color_rect.offset_left = 0
		color_rect.offset_top = 0
		color_rect.offset_right = 0
		color_rect.offset_bottom = 0
		color_rect.size = viewport_size
	
	# Make sure CenterContainer covers the full area
	if has_node("CenterContainer"):
		var center = $CenterContainer
		center.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		center.anchor_left = 0
		center.anchor_top = 0
		center.anchor_right = 1
		center.anchor_bottom = 1
		center.offset_left = 0
		center.offset_top = 0
		center.offset_right = 0
		center.offset_bottom = 0
		center.size = viewport_size

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
	# Show darkness when the pause menu is hidden
	toggle_darkness(true)

func _on_settings_pressed():
	# Disable all pause menu buttons
	disable_all_buttons()
	
	# First check if there's already a settings menu in the scene tree
	var existing_settings = get_tree().root.get_node_or_null("SettingsMenu")
	
	if existing_settings:
		settings_instance = existing_settings
		# Set to match pause menu size
		apply_settings_size(settings_instance)
		settings_instance.show()
		return
	
	if not settings_instance:
		settings_instance = settings_scene.instantiate()
		settings_instance.name = "SettingsMenu"  # Give it a consistent name
		get_tree().root.add_child(settings_instance)
		# Set to match pause menu size
		apply_settings_size(settings_instance)
		settings_instance.settings_closed.connect(_on_settings_closed)
		
		# Make sure game stays paused when settings are open
		settings_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	else:
		# Set to match pause menu size
		apply_settings_size(settings_instance)
		settings_instance.show()

func apply_settings_size(settings_menu):
	# Ensure settings appears above pause menu
	settings_menu.z_index = z_index + 10
	
	if game_camera:
		# Use camera dimensions for settings menu
		var camera_size = get_camera_view_size()
		
		# Make settings menu a top-level control to ensure proper positioning
		settings_menu.top_level = true
		
		# Reset transform
		settings_menu.position = Vector2.ZERO
		settings_menu.scale = Vector2.ONE
		settings_menu.rotation = 0
		
		# Set size to match camera view
		settings_menu.size = camera_size
		settings_menu.custom_minimum_size = camera_size
		
		# Center on camera
		settings_menu.global_position = get_camera_screen_center() - (camera_size / 2)
		
		# Make sure the settings menu's internal elements fill the entire area
		if settings_menu.has_node("CenterContainer"):
			var center = settings_menu.get_node("CenterContainer")
			center.set_anchors_preset(Control.PRESET_FULL_RECT, true)
			center.size = camera_size
			
			# Don't scale the panel itself, but scale all its children instead
			if center.has_node("PanelContainer"):
				var panel = center.get_node("PanelContainer")
				
				# Scale individual elements instead of the whole panel
				# This ensures interactable elements scale properly
				_scale_all_controls_recursively(panel, settings_scale_factor)
	else:
		# Fallback to viewport size
		var viewport_size = get_viewport_rect().size
		
		# Make settings menu a top-level control
		settings_menu.top_level = true
		
		# Reset transform
		settings_menu.position = Vector2.ZERO
		settings_menu.scale = Vector2.ONE
		settings_menu.rotation = 0
		
		# Fill the viewport
		settings_menu.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		settings_menu.anchor_left = 0
		settings_menu.anchor_top = 0
		settings_menu.anchor_right = 1
		settings_menu.anchor_bottom = 1
		settings_menu.offset_left = 0
		settings_menu.offset_top = 0
		settings_menu.offset_right = 0
		settings_menu.offset_bottom = 0
		settings_menu.size = viewport_size
		settings_menu.custom_minimum_size = viewport_size

# Helper function to scale controls recursively
func _scale_all_controls_recursively(node, scale_factor):
	# Scale font sizes and control sizes for different control types
	if node is Control:
		# Handle different controls
		if node is Label:
			# Scale label font size
			if node.has_theme_override("font_size"):
				var current_size = node.get_theme_font_size("font_size")
				node.add_theme_font_size_override("font_size", int(current_size * scale_factor))
			else:
				node.add_theme_font_size_override("font_size", int(22 * scale_factor))  # Default size
		
		elif node is Button:
			# Scale button font size
			if node.has_theme_override("font_size"):
				var current_size = node.get_theme_font_size("font_size")
				node.add_theme_font_size_override("font_size", int(current_size * scale_factor))
			else:
				node.add_theme_font_size_override("font_size", int(22 * scale_factor))  # Default size
			
			# Increase button's minimum size
			if node.custom_minimum_size != Vector2.ZERO:
				node.custom_minimum_size *= scale_factor
			else:
				node.custom_minimum_size = Vector2(100, 50) * scale_factor
		
		elif node is LineEdit or node is SpinBox or node is Slider:
			# Scale input controls
			if node.has_theme_override("font_size"):
				var current_size = node.get_theme_font_size("font_size")
				node.add_theme_font_size_override("font_size", int(current_size * scale_factor))
			else:
				node.add_theme_font_size_override("font_size", int(18 * scale_factor))
				
			# Increase control size
			if node.custom_minimum_size != Vector2.ZERO:
				node.custom_minimum_size *= scale_factor
			else:
				node.custom_minimum_size = Vector2(150, 40) * scale_factor
		
		elif node is HBoxContainer or node is VBoxContainer:
			# Increase spacing between elements
			node.add_theme_constant_override("separation", int(10 * scale_factor))
			
			# Set custom minimum size for containers
			if node.custom_minimum_size != Vector2.ZERO:
				node.custom_minimum_size *= scale_factor
		
		# For all other controls, scale custom minimum size if set
		elif node.custom_minimum_size != Vector2.ZERO:
			node.custom_minimum_size *= scale_factor
	
	# Process children
	for child in node.get_children():
		_scale_all_controls_recursively(child, scale_factor)

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
