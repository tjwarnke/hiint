extends Node2D

var chandelierLight
var painting

var lever1
var lever2
var writing
var poolTable
var poolTableArea
var safe
var safePlatform 

var in_lever1 = false
var in_lever2 = false
var in_safe = false
var in_pool_table

var player
func _ready():
	safe = get_node("Safe/Area2D")
	chandelierLight = get_node("MidgroundTilemap/Chandalier2/PointLight2D")
	painting = get_node("MidgroundTilemap/Painting")
	lever1 = get_node("Lever1")
	lever2 = get_node("Lever2")
	writing = get_node("BloodWriting")
	poolTable = get_node("PoolTable")
	poolTableArea = get_node("PoolTable/Area2D")
	safePlatform = get_node("SafePlatform")
	lever1.body_entered.connect( _on_lever_1_body_entered)
	lever2.body_entered.connect( _on_lever_2_body_entered)
	safe.body_entered.connect( _on_safe_body_entered)
	poolTableArea.body_entered.connect( _on_pool_table_body_entered)
	lever1.body_exited.connect( _on_lever_1_body_exited)
	lever2.body_exited.connect( _on_lever_2_body_exited)
	safe.body_exited.connect( _on_safe_body_exited)
	poolTableArea.body_exited.connect( _on_pool_table_body_exited)
	safe.hide()
	writing.hide()
	chandelierLight.hide()
	safePlatform.hide()
	
func _input(event: InputEvent) -> void:
	if in_lever1 and event.is_action_pressed("pick_up"):
		lever1_action()
	if in_lever2 and event.is_action_pressed("pick_up"):
		lever2_action()
	if in_safe and event.is_action_pressed("pick_up"):
		safe_action()
	if in_pool_table and event.is_action_pressed("pick_up") and player.hasItem("8-ball"):
		dungeon_drop()
		
func lever1_action():
	painting.hide()
	safe.show()
	safePlatform.show()

func lever2_action():
	chandelierLight.show()
	writing.show()
	
func safe_action():
	#player has to select the numbers 10-31-84
	#OR, if player hasnt found the code, doesnt work, if playef has, does work
	pass
	
func dungeon_drop():
	#TODO: show text and destroy the 8 ball
	#player.dropItem("8-Ball", true)
	door_open()

func _on_lever_1_body_entered(body):
	if body.is_in_group("player"):
		in_lever1 = true
		player = body
	
func _on_lever_2_body_entered(body):
	if body.is_in_group("player"):
		in_lever2= true
		player = body
	
func _on_safe_body_entered(body):
	if body.is_in_group("player"):
		in_safe = true
		player = body
		
func _on_pool_table_body_entered(body):
	if body.is_in_group("player"):
		in_pool_table = true
		player = body
	
func _on_lever_1_body_exited(body):
	in_lever1 = false
	
func _on_lever_2_body_exited(body):
	in_lever2 = false
	
func _on_safe_body_exited(body):
	in_safe = false
	
func _on_pool_table_body_exited(body):
	in_pool_table = false
	
func door_open():
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player:
		anim_player.play("door_fall")
		# Wait for animation to finish
		await anim_player.animation_finished
		
		# Clear the DropNode queue
		var drop_node = get_node_or_null("DropNode")
		if drop_node:
			drop_node.queue_free()
	else:
		push_warning("AnimationPlayer not found in billiards room scene")
