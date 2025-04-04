extends Node

# Scene paths
const SCENE_PATHS = {
	"tutorial": "res://scenes/second_tutorial.tscn",
	"dining_room": "res://scenes/dining_room.tscn",
	"library": "res://scenes/library.tscn",
	"billiards_room": "res://scenes/billiards_room.tscn",
	"dungeon": "res://scenes/dungeon.tscn"
}

# Scene loading order
const LOAD_ORDER = [
	"tutorial",
	"dining_room",
	"library",
	"billiards_room",
	"dungeon"
]

# Scene instances and their states
var loaded_scenes = {}
var current_scene_index = 0
var world_attach_node: Node2D
var current_attach_node: Node2D

# Scene loading thread
var loading_thread: Thread
var mutex: Mutex

func _ready():
	mutex = Mutex.new()
	loading_thread = Thread.new()
	
	# Find the World node and its AttachRight node
	var world_node = get_parent()
	if world_node and world_node.name == "World":
		world_attach_node = world_node.get_node_or_null("AttachRight")
		if not world_attach_node:
			# Try to find the Attach node if AttachRight doesn't exist
			world_attach_node = world_node.get_node_or_null("Attach")
		
		if world_attach_node:
			print("Found World attach node at position: ", world_attach_node.global_position)
			loading_thread.start(Callable(self, "load_scenes_in_background"))
		else:
			push_error("No attach node found in World scene!")
	else:
		push_error("SceneManager must be a child of the World node!")

# This function is called from World.gd to set the world attach node
func initialize(world_attach: Node2D):
	world_attach_node = world_attach
	print("World attach node set to: ", world_attach)
	
	if world_attach_node:
		loading_thread.start(Callable(self, "load_scenes_in_background"))
	else:
		push_error("World attach node is null!")

func load_scenes_in_background():
	# Load first scene
	load_first_scene()
	
	# Load remaining scenes in sequence
	for i in range(1, LOAD_ORDER.size()):
		load_next_scene(i)

func load_first_scene():
	if not world_attach_node:
		push_error("World attach node is missing!")
		return
		
	var first_scene_name = LOAD_ORDER[0]
	var first_scene_path = SCENE_PATHS[first_scene_name]
	var first_scene = load(first_scene_path)
	
	if not first_scene:
		push_error("Failed to load scene: " + first_scene_path)
		return
		
	var instance = first_scene.instantiate()
	if not instance:
		push_error("Failed to instantiate scene: " + first_scene_path)
		return
		
	# Find the AttachLeft node in the instantiated scene
	var attach_left = instance.get_node_or_null("AttachLeft")
	if not attach_left:
		print("AttachLeft node not found in scene: " + first_scene_path)
		print("Creating temporary AttachLeft node")
		attach_left = Node2D.new()
		attach_left.name = "AttachLeft"
		instance.add_child(attach_left)
		attach_left.position = Vector2(0, 0)
		
	# Position the scene so AttachLeft aligns with the world's Attach node
	instance.global_position = world_attach_node.global_position - attach_left.global_position
	
	# Add the scene as a child
	call_deferred("add_child", instance)
	
	# Store the loaded scene and update the current attach node
	mutex.lock()
	loaded_scenes[first_scene_name] = instance
	mutex.unlock()
	
	# Set the current attach node for the next scene
	current_attach_node = instance.get_node_or_null("AttachRight")
	if not current_attach_node:
		# If AttachRight is not found, try to use the right edge of the scene
		print("AttachRight node not found in first scene: " + first_scene_path)
		print("Using scene width to estimate attach point")
		# Create a temporary attach node at the right edge of the scene
		var temp_attach = Node2D.new()
		temp_attach.name = "TempAttach"
		instance.add_child(temp_attach)
		# Position it at the right edge of the scene (assuming the scene has a width)
		# This is a rough estimate and may need adjustment
		var tilemap = instance.get_node_or_null("TileMap")
		if tilemap:
			temp_attach.position = Vector2(tilemap.get_used_rect().size.x * 16, 0)
		else:
			# Fallback if no TileMap is found
			temp_attach.position = Vector2(1000, 0)  # Default width
		current_attach_node = temp_attach
	
	print("Loaded first scene: ", first_scene_name)

func load_next_scene(index: int):
	if not current_attach_node:
		push_error("Current attach node is missing!")
		return
		
	var scene_name = LOAD_ORDER[index]
	var scene_path = SCENE_PATHS[scene_name]
	var scene = load(scene_path)
	
	if not scene:
		push_error("Failed to load scene: " + scene_path)
		return
		
	var instance = scene.instantiate()
	if not instance:
		push_error("Failed to instantiate scene: " + scene_path)
		return
		
	# Find the AttachLeft node in the instantiated scene
	var attach_left = instance.get_node_or_null("AttachLeft")
	if not attach_left:
		print("AttachLeft node not found in scene: " + scene_path)
		print("Creating temporary AttachLeft node")
		attach_left = Node2D.new()
		attach_left.name = "AttachLeft"
		instance.add_child(attach_left)
		attach_left.position = Vector2(0, 0)
		
	# Position the scene so AttachLeft aligns with the current scene's Attach node
	instance.global_position = current_attach_node.global_position - attach_left.global_position
	
	# Add the scene as a child
	call_deferred("add_child", instance)
	
	# Store the loaded scene and update the current attach node
	mutex.lock()
	loaded_scenes[scene_name] = instance
	mutex.unlock()
	
	# Update the current attach node for the next scene
	current_attach_node = instance.get_node_or_null("AttachRight")
	if not current_attach_node:
		# If AttachRight is not found, try to use the right edge of the scene
		print("AttachRight node not found in scene: " + scene_path)
		print("Using scene width to estimate attach point")
		# Create a temporary attach node at the right edge of the scene
		var temp_attach = Node2D.new()
		temp_attach.name = "TempAttach"
		instance.add_child(temp_attach)
		# Position it at the right edge of the scene (assuming the scene has a width)
		# This is a rough estimate and may need adjustment
		var tilemap = instance.get_node_or_null("TileMap")
		if tilemap:
			temp_attach.position = Vector2(tilemap.get_used_rect().size.x * 16, 0)
		else:
			# Fallback if no TileMap is found
			temp_attach.position = Vector2(1000, 0)  # Default width
		current_attach_node = temp_attach
	
	print("Loaded scene: ", scene_name)

func unload_scene(scene_name: String):
	mutex.lock()
	if loaded_scenes.has(scene_name):
		var scene = loaded_scenes[scene_name]
		scene.queue_free()
		loaded_scenes.erase(scene_name)
	mutex.unlock()

func get_scene(scene_name: String) -> Node:
	mutex.lock()
	var scene = loaded_scenes.get(scene_name)
	mutex.unlock()
	return scene

func _exit_tree():
	if loading_thread and loading_thread.is_started():
		loading_thread.wait_to_finish()
