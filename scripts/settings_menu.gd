extends Control

# Constants
const CONFIG_FILE = "user://settings.cfg"
const AUDIO_BUS_MASTER = "Master"
const AUDIO_BUS_MUSIC = "Music"
const AUDIO_BUS_AMBIENT = "Ambient"
const AUDIO_BUS_SPOOKY = "Spooky"

# Key binding action names
const KEY_BINDINGS = {
	"jump": "Jump",
	"left": "Move Left",
	"right": "Move Right",
	"fast_fall": "Move Down",
	"pick_up": "Interact",
	"set_down": "Drop",
	"dash": "Dash"
}

# Common resolutions
const RESOLUTIONS = [
	Vector2i(1280, 720),   # 720p
	Vector2i(1366, 768),   # Common laptop resolution
	Vector2i(1600, 900),   # 900p
	Vector2i(1920, 1080),  # 1080p
	Vector2i(2560, 1440),  # 1440p
	Vector2i(3840, 2160)   # 4K
]

# Node references
@onready var tab_container = $MarginContainer/VBoxContainer/TabContainer
@onready var apply_button = $MarginContainer/VBoxContainer/Buttons/ApplyButton
@onready var back_button = $MarginContainer/VBoxContainer/Buttons/BackButton

# Save Changes Dialog
@onready var save_changes_dialog = $SaveChangesDialog
@onready var save_button = $SaveChangesDialog/PanelContainer/VBoxContainer/HBoxContainer/SaveButton
@onready var discard_button = $SaveChangesDialog/PanelContainer/VBoxContainer/HBoxContainer/DiscardButton

# Audio sliders
@onready var master_slider = $MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MasterVolume/HBoxContainer/MasterSlider
@onready var master_value_label = $MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MasterVolume/HBoxContainer/ValueLabel
@onready var music_slider = $MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicVolume/HBoxContainer/MusicSlider
@onready var music_value_label = $MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicVolume/HBoxContainer/ValueLabel
@onready var ambient_slider = $MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/AmbientVolume/HBoxContainer/AmbientSlider
@onready var ambient_value_label = $MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/AmbientVolume/HBoxContainer/ValueLabel
@onready var spooky_slider = $MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/SpookyVolume/HBoxContainer/SpookySlider
@onready var spooky_value_label = $MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/SpookyVolume/HBoxContainer/ValueLabel

# Key binding buttons
@onready var key_binding_buttons = {
	"jump": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/Jump/Button,
	"left": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/MoveLeft/Button,
	"right": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/MoveRight/Button,
	"fast_fall": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/MoveDown/Button,
	"pick_up": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/Interact/Button,
	"set_down": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/Drop/Button,
	"dash": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/Dash/Button
}

# Key binding labels
@onready var key_binding_labels = {
	"jump": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/Jump/CurrentBinding,
	"left": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/MoveLeft/CurrentBinding,
	"right": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/MoveRight/CurrentBinding,
	"fast_fall": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/MoveDown/CurrentBinding,
	"pick_up": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/Interact/CurrentBinding,
	"set_down": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/Drop/CurrentBinding,
	"dash": $MarginContainer/VBoxContainer/TabContainer/General/VBoxContainer/KeyBindings/Dash/CurrentBinding
}

# Display settings
@onready var window_mode_option = $MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/WindowMode/OptionButton
@onready var resolution_option = $MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/Resolution/OptionButton
@onready var vsync_check = $MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/VSync/CheckButton

# Config data
var config = ConfigFile.new()
var current_key_binding_button = null
var waiting_for_key = false
var has_unsaved_changes = false
var position_in_center = false

func _ready():
	# Initialize config
	config = ConfigFile.new()
	
	# Ensure all input actions exist with default bindings first
	ensure_input_actions_exist()
	
	# Set up audio buses if they don't exist
	setup_audio_buses()
	
	# Initialize UI
	populate_resolution_options()
	
	# Connect signals
	connect_signals()
	
	# Load saved settings
	load_settings()
	
	# Set up key binding buttons to display the current bindings
	setup_key_binding_buttons()
	
	# Apply initial settings
	update_audio_settings()
	update_display_settings()
	
	# Hide the save changes dialog
	save_changes_dialog.hide()
	
	# Set proper UI positioning
	set_proper_positioning()
	
	# Ensure we're on top
	top_level = true
	z_index = 100

func set_proper_positioning():
	if position_in_center:
		# In-game context: Center the menu with a semi-transparent background
		
		# First, set anchors to fill the screen
		set_anchors_preset(Control.PRESET_FULL_RECT)
		anchor_right = 1.0
		anchor_bottom = 1.0
		offset_left = 0
		offset_top = 0
		offset_right = 0
		offset_bottom = 0
		
		# Darken the background
		$ColorRect.color = Color(0, 0, 0, 0.8)
		
		# Center the main container
		$MarginContainer.set_anchors_preset(Control.PRESET_CENTER)
		$MarginContainer.anchor_left = 0.5
		$MarginContainer.anchor_top = 0.5
		$MarginContainer.anchor_right = 0.5
		$MarginContainer.anchor_bottom = 0.5
		$MarginContainer.offset_left = -600
		$MarginContainer.offset_top = -350
		$MarginContainer.offset_right = 600
		$MarginContainer.offset_bottom = 350
		
		# Make margin container take direct size
		$MarginContainer.add_theme_constant_override("margin_left", 50)
		$MarginContainer.add_theme_constant_override("margin_top", 50)
		$MarginContainer.add_theme_constant_override("margin_right", 50)
		$MarginContainer.add_theme_constant_override("margin_bottom", 50)
	else:
		# Start menu context: Full screen display
		
		# Set anchors to fill the screen
		set_anchors_preset(Control.PRESET_FULL_RECT)
		anchor_right = 1.0
		anchor_bottom = 1.0
		offset_left = 0
		offset_top = 0
		offset_right = 0
		offset_bottom = 0
		
		# Reset margin container to full screen
		$MarginContainer.set_anchors_preset(Control.PRESET_FULL_RECT)
		$MarginContainer.anchor_right = 1.0
		$MarginContainer.anchor_bottom = 1.0
		$MarginContainer.offset_left = 0
		$MarginContainer.offset_top = 0
		$MarginContainer.offset_right = 0
		$MarginContainer.offset_bottom = 0
		
		# Restore original margins
		$MarginContainer.add_theme_constant_override("margin_left", 100)
		$MarginContainer.add_theme_constant_override("margin_top", 50)
		$MarginContainer.add_theme_constant_override("margin_right", 100)
		$MarginContainer.add_theme_constant_override("margin_bottom", 50)

func ensure_input_actions_exist():
	# Make sure all key bindings actions exist in the InputMap
	for action in KEY_BINDINGS:
		var needs_default = false
		
		# Check if action exists, create if not
		if not InputMap.has_action(action):
			print("Creating missing input action: ", action)
			InputMap.add_action(action)
			needs_default = true
		elif InputMap.action_get_events(action).size() == 0:
			# Action exists but has no events
			needs_default = true
			
		# Add a default key binding if needed
		if needs_default:
			print("Adding default binding for action: ", action)
			var default_event = InputEventKey.new()
			match action:
				"jump":
					default_event.keycode = KEY_W
				"left":
					default_event.keycode = KEY_A
				"right":
					default_event.keycode = KEY_D
				"fast_fall":
					default_event.keycode = KEY_S
				"pick_up":
					default_event.keycode = KEY_E
				"set_down":
					default_event.keycode = KEY_Q
				"dash":
					default_event.keycode = KEY_SHIFT
				_:
					# Default for any other actions
					default_event.keycode = KEY_F
			
			InputMap.action_add_event(action, default_event)
			
			# Force an existing config value to be removed if it exists
			if config.has_section_key("key_bindings", action):
				config.erase_section_key("key_bindings", action)

func setup_audio_buses():
	# Check if the audio buses exist and create them if needed
	var _master_idx = AudioServer.get_bus_index(AUDIO_BUS_MASTER)
	
	# Music bus
	var music_idx = AudioServer.get_bus_index(AUDIO_BUS_MUSIC)
	if music_idx == -1:
		music_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(music_idx, AUDIO_BUS_MUSIC)
		AudioServer.set_bus_send(music_idx, AUDIO_BUS_MASTER)
	
	# Ambient bus
	var ambient_idx = AudioServer.get_bus_index(AUDIO_BUS_AMBIENT)
	if ambient_idx == -1:
		ambient_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(ambient_idx, AUDIO_BUS_AMBIENT)
		AudioServer.set_bus_send(ambient_idx, AUDIO_BUS_MASTER)
	
	# Spooky bus
	var spooky_idx = AudioServer.get_bus_index(AUDIO_BUS_SPOOKY)
	if spooky_idx == -1:
		spooky_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(spooky_idx, AUDIO_BUS_SPOOKY)
		AudioServer.set_bus_send(spooky_idx, AUDIO_BUS_MASTER)

func connect_signals():
	# Audio sliders
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	ambient_slider.value_changed.connect(_on_ambient_volume_changed)
	spooky_slider.value_changed.connect(_on_spooky_volume_changed)
	
	# Display settings
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)
	vsync_check.toggled.connect(_on_vsync_toggled)
	
	# Buttons
	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Save changes dialog
	save_button.pressed.connect(_on_save_button_pressed)
	discard_button.pressed.connect(_on_discard_button_pressed)

func setup_key_binding_buttons():
	print("Setting up key binding buttons...")
	# Connect each key binding button
	for action in key_binding_buttons:
		var button = key_binding_buttons[action]
		var label = key_binding_labels[action]
		
		if button and label:
			button.pressed.connect(_on_key_binding_button_pressed.bind(action, button, label))
			
			# Set the initial button text based on the current input mapping
			update_key_binding_label(action, label)
			print("Connected key binding button for action: ", action)
		else:
			push_error("Button or label for action " + action + " not found!")

func update_key_binding_label(action, label):
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		# Get the first event (we only support one key per action for simplicity)
		var event = events[0]
		if event is InputEventKey:
			var key_string = OS.get_keycode_string(event.keycode)
			if key_string.is_empty() and event.keycode != 0:
				# If getting the key string failed but we have a valid keycode
				key_string = "Key " + str(event.keycode)
			
			label.text = key_string if not key_string.is_empty() else "None"
		else:
			label.text = "None"
	else:
		# This should not happen after ensure_input_actions_exist, but just in case
		label.text = "None"
		print("Warning: No events for action ", action)

func _on_key_binding_button_pressed(action, button, label):
	print("Key binding button pressed for action: ", action)
	# We're now waiting for a key press
	waiting_for_key = true
	current_key_binding_button = button
	
	# Change the label's text to indicate waiting
	label.text = "Press a key..."
	
	# Store the action name for later use when the key is pressed
	button.set_meta("action", action)
	label.set_meta("action", action)

func _input(event):
	if waiting_for_key and current_key_binding_button:
		if event is InputEventKey and event.pressed and not event.is_echo():
			# Get the action name from the button's metadata
			var action = current_key_binding_button.get_meta("action")
			var label = key_binding_labels[action]
			
			print("New key assigned to action: ", action, " - Key: ", OS.get_keycode_string(event.keycode))
			
			# Update the input mapping
			update_key_binding(action, event)
			
			# Update the label's text
			update_key_binding_label(action, label)
			
			# No longer waiting for a key press
			waiting_for_key = false
			current_key_binding_button = null
			
			# Set flag for unsaved changes
			has_unsaved_changes = true
			
			# Prevent the event from propagating
			get_viewport().set_input_as_handled()
			return
	
	# Check for escape key to show the confirmation dialog
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE:
		if visible and not save_changes_dialog.visible and not waiting_for_key:
			if has_unsaved_changes:
				# Show confirmation dialog
				save_changes_dialog.show()
			else:
				# No changes, just close
				hide()
				emit_signal("settings_closed")
			
			# Prevent the event from propagating
			get_viewport().set_input_as_handled()

func update_key_binding(action, event):
	# Clear the existing key bindings for this action
	InputMap.action_erase_events(action)
	
	# Add the new key binding
	InputMap.action_add_event(action, event)

func populate_resolution_options():
	resolution_option.clear()
	
	# Add current desktop resolution first
	var current_res = DisplayServer.screen_get_size()
	resolution_option.add_item(str(current_res.x) + "x" + str(current_res.y) + " (Native)")
	
	# Add common resolutions if they're not already in the list
	for res in RESOLUTIONS:
		if res != current_res:
			resolution_option.add_item(str(res.x) + "x" + str(res.y))

func _on_master_volume_changed(value):
	master_value_label.text = str(int(value * 100)) + "%"
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AUDIO_BUS_MASTER), db)
	has_unsaved_changes = true

func _on_music_volume_changed(value):
	music_value_label.text = str(int(value * 100)) + "%"
	var db = linear_to_db(value)
	var bus_idx = AudioServer.get_bus_index(AUDIO_BUS_MUSIC)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, db)
	has_unsaved_changes = true

func _on_ambient_volume_changed(value):
	ambient_value_label.text = str(int(value * 100)) + "%"
	var db = linear_to_db(value)
	var bus_idx = AudioServer.get_bus_index(AUDIO_BUS_AMBIENT)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, db)
	has_unsaved_changes = true

func _on_spooky_volume_changed(value):
	spooky_value_label.text = str(int(value * 100)) + "%"
	var db = linear_to_db(value)
	var bus_idx = AudioServer.get_bus_index(AUDIO_BUS_SPOOKY)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, db)
	has_unsaved_changes = true

func _on_window_mode_selected(index):
	match index:
		0: # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1: # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		2: # Borderless Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	has_unsaved_changes = true

func _on_resolution_selected(index):
	var selected_text = resolution_option.get_item_text(index)
	var res_parts = selected_text.split("x")
	if res_parts.size() >= 2:
		var width = res_parts[0].to_int()
		# Remove any text in parentheses for the height
		var height_text = res_parts[1].split(" ")[0]
		var height = height_text.to_int()
		
		if width > 0 and height > 0:
			DisplayServer.window_set_size(Vector2i(width, height))
			# Center the window if not in fullscreen
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
				var screen_size = DisplayServer.screen_get_size()
				var window_pos = (screen_size - Vector2i(width, height)) / 2
				DisplayServer.window_set_position(window_pos)
	has_unsaved_changes = true

func _on_vsync_toggled(button_pressed):
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	has_unsaved_changes = true

func _on_apply_pressed():
	save_settings()
	has_unsaved_changes = false
	print("Settings applied and saved")

func _on_back_pressed():
	if has_unsaved_changes:
		# Show confirmation dialog
		save_changes_dialog.show()
	else:
		# No changes, just close
		hide()
		emit_signal("settings_closed")

func _on_save_button_pressed():
	save_settings()
	has_unsaved_changes = false
	save_changes_dialog.hide()
	hide()
	emit_signal("settings_closed")

func _on_discard_button_pressed():
	# Discard changes
	has_unsaved_changes = false
	save_changes_dialog.hide()
	hide()
	emit_signal("settings_closed")

# Signal to notify that settings have been closed
signal settings_closed

func load_settings():
	var err = config.load(CONFIG_FILE)
	if err != OK:
		print("No settings file found, using defaults")
		return
	
	# Audio settings
	if config.has_section("audio"):
		master_slider.value = config.get_value("audio", "master_volume", 1.0)
		music_slider.value = config.get_value("audio", "music_volume", 1.0)
		ambient_slider.value = config.get_value("audio", "ambient_volume", 1.0)
		spooky_slider.value = config.get_value("audio", "spooky_volume", 1.0)
	
	# Key bindings
	if config.has_section("key_bindings"):
		for action in KEY_BINDINGS:
			var key_code = config.get_value("key_bindings", action, null)
			if key_code != null:
				# Create a new input event with the saved key code
				var event = InputEventKey.new()
				event.keycode = key_code
				
				# Update the input mapping
				update_key_binding(action, event)
				
				# Update the label
				if key_binding_labels.has(action):
					var label = key_binding_labels[action]
					update_key_binding_label(action, label)
	
	# Display settings
	if config.has_section("display"):
		var window_mode = config.get_value("display", "window_mode", 0)
		window_mode_option.select(window_mode)
		
		var vsync = config.get_value("display", "vsync", true)
		vsync_check.button_pressed = vsync
		
		var resolution_str = config.get_value("display", "resolution", "")
		if resolution_str != "":
			for i in range(resolution_option.item_count):
				if resolution_option.get_item_text(i).begins_with(resolution_str):
					resolution_option.select(i)
					break
	
	# Reset unsaved changes flag
	has_unsaved_changes = false

func save_settings():
	# Audio settings
	config.set_value("audio", "master_volume", master_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "ambient_volume", ambient_slider.value)
	config.set_value("audio", "spooky_volume", spooky_slider.value)
	
	# Key bindings
	for action in KEY_BINDINGS:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event = events[0]
			if event is InputEventKey:
				config.set_value("key_bindings", action, event.keycode)
	
	# Display settings
	config.set_value("display", "window_mode", window_mode_option.selected)
	config.set_value("display", "vsync", vsync_check.button_pressed)
	
	var selected_res = resolution_option.get_item_text(resolution_option.selected)
	var res_parts = selected_res.split("x")
	if res_parts.size() >= 2:
		var width = res_parts[0].to_int()
		var height_text = res_parts[1].split(" ")[0]
		var height = height_text.to_int()
		config.set_value("display", "resolution", str(width) + "x" + str(height))
	
	# Save to file
	var err = config.save(CONFIG_FILE)
	if err != OK:
		push_error("Failed to save settings: " + str(err))

func update_audio_settings():
	_on_master_volume_changed(master_slider.value)
	_on_music_volume_changed(music_slider.value)
	_on_ambient_volume_changed(ambient_slider.value)
	_on_spooky_volume_changed(spooky_slider.value)

func update_display_settings():
	_on_window_mode_selected(window_mode_option.selected)
	_on_resolution_selected(resolution_option.selected)
	_on_vsync_toggled(vsync_check.button_pressed)

# Apply the audio bus settings to the given audio player
static func apply_audio_settings_to_player(audio_player, bus_name):
	if audio_player != null:
		audio_player.bus = bus_name 

func set_position_in_center(value):
	position_in_center = value
	# If we're already in the scene tree, update positioning immediately
	if is_inside_tree():
		set_proper_positioning() 
