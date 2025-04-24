extends Node2D

var door
var doors
var glass1
var glass2
var hammer
var lever1
var lever2
var lever3
var key
var cageDoor1
var cageDoor2
var trapdoor
var ladder
var ladderArea

var doorArea
var glass1Area
var glass2Area
var lever1Area
var lever2Area
var lever3Area


var puz_lvr_1
var puz_lvr_1Area
var puz_lvr_2
var puz_lvr_2Area
var puz_lvr_3
var puz_lvr_3Area

var in_puz_lvr_1 = false
var in_puz_lvr_2 = false
var in_puz_lvr_3 = false

var in_lever1 = false
var in_lever2 = false
var in_lever3 = false
var in_glass1 = false
var in_glass2 = false
var in_door = false
var in_ladder = false

var checkPuz1 = true
var checkPuz2 = false 
var checkPuz3 = false

var player

func _ready():
	door = get_node("Door")
	doorArea = get_node("Door/Area2D")
	doors = get_node("Doors")
	glass1 = get_node("Glass1")
	glass1Area = get_node("Glass1/Area2D")
	glass2 = get_node("Glass2")
	glass2Area = get_node("Glass2/Area2D")
	hammer = get_node("Hammer")
	lever1 = get_node("Lever")
	lever1Area = get_node("Lever/Area2D")
	lever2 = get_node("Lever2")
	lever2Area = get_node("Lever2/Area2D")
	lever3 = get_node("Lever3")
	lever3Area = get_node("Lever3/Area2D")
	key = get_node("Key")
	cageDoor1 = get_node("CageDoor1")
	cageDoor2 = get_node("CageDoor2")
	player = get_node_or_null("/root/World/Player")
	puz_lvr_1 = get_node("PuzzleLever1")
	puz_lvr_1Area = get_node("PuzzleLever1/Area2D")
	puz_lvr_2 = get_node("PuzzleLever2")
	puz_lvr_2Area = get_node("PuzzleLever2/Area2D")
	puz_lvr_3 = get_node("PuzzleLever3")
	puz_lvr_3Area = get_node("PuzzleLever3/Area2D")
	trapdoor = get_node("Trapdoor")
	ladder = get_node("Ladder")
	ladderArea = get_node("Ladder/Area2D")
	doorArea.body_entered.connect( _on_body_door_entered)
	lever1Area.body_entered.connect( _on_body_lvr1_entered)
	lever2Area.body_entered.connect( _on_body_lvr2_entered)
	lever3Area.body_entered.connect( _on_body_lvr3_entered)
	puz_lvr_1Area.body_entered.connect( _on_body_pzl_lvr1_entered)
	puz_lvr_2Area.body_entered.connect( _on_body_pzl_lvr2_entered)
	puz_lvr_3Area.body_entered.connect( _on_body_pzl_lvr3_entered)
	ladderArea.body_entered.connect( _on_body_ladder_entered)
	glass1Area.body_entered.connect( _on_body_glass1_entered)
	glass2Area.body_entered.connect( _on_body_glass2_entered)
	
	doorArea.body_exited.connect( _on_door_body_exited)
	lever1Area.body_exited.connect( _on_lvr1_body_exited)
	lever2Area.body_exited.connect( _on_lvr2_body_exited)
	lever3Area.body_exited.connect( _on_lvr3_body_exited)
	puz_lvr_1Area.body_exited.connect( _on_pzl_lvr1_body_exited)
	puz_lvr_2Area.body_exited.connect( _on_pzl_lvr2_body_exited)
	puz_lvr_3Area.body_exited.connect( _on_pzl_lvr3_body_exited)
	ladderArea.body_exited.connect( _on_ladder_body_exited)
	glass1Area.body_exited.connect( _on_glass1_body_exited)
	glass2Area.body_exited.connect( _on_glass2_body_exited)
	
	
func _input(event: InputEvent) -> void:
	if !player:
		player = get_node("/root/World/Player")
	if in_lever1 and event.is_action_pressed("pick_up"):
		lever1_action()
	if in_lever2 and event.is_action_pressed("pick_up"):
		lever2_action()
	if in_lever3 and event.is_action_pressed("pick_up"):
		lever3_action()
	if in_glass1 and event.is_action_pressed("pick_up") and player.hasItem(hammer):
		glass1_break()
	if in_glass2 and event.is_action_pressed("pick_up") and player.hasItem(hammer):
		glass2_break()
	if in_door and event.is_action_pressed("pick_up") and player.hasItem(key):
		open_door()
	if in_puz_lvr_1 and event.is_action_pressed("pick_up"):
		checkPuz1 = !checkPuz1
		check_puzzle()
	if in_puz_lvr_2 and event.is_action_pressed("pick_up"):
		checkPuz2 = !checkPuz2
		check_puzzle()
	if in_puz_lvr_2 and event.is_action_pressed("pick_up"):
		checkPuz3 = !checkPuz3
		check_puzzle()
	if in_ladder and event.is_action_pressed("pick_up"):
		climb_ladder()
		
func lever1_action():
	cageDoor1.hide()
	#TODO: play sound and animation
	
func lever2_action():
	cageDoor2.hide()
	#TODO: play sound and animation
	
func lever3_action():
	doors.hide()
	#TODO: play sound and animation
	
func glass1_break():
	#TODO: play a sound
	glass1.hide()
	
func glass2_break():
	#TODO: play a sound
	glass2.hide()
	
func open_door():
	door.hide()
	#TODO: play a sound

func check_puzzle():
	if checkPuz1 and checkPuz2 and checkPuz3:
		trapdoor.hide()
		
func climb_ladder():
	#TODO: change scene back to dining room and play final cutscene
	pass

func _on_body_lvr1_entered(body):
	if body.is_in_group("player"):
		in_lever1 = true
		player = body
		
func _on_body_lvr2_entered(body):
	if body.is_in_group("player"):
		in_lever2 = true
		player = body
		
func _on_body_lvr3_entered(body):
	if body.is_in_group("player"):
		in_lever3 = true
		player = body
		
func _on_body_pzl_lvr1_entered(body):
	if body.is_in_group("player"):
		in_puz_lvr_1 = true
		player = body
		
func _on_body_pzl_lvr2_entered(body):
	if body.is_in_group("player"):
		in_puz_lvr_2 = true
		player = body
		
func _on_body_pzl_lvr3_entered(body):
	if body.is_in_group("player"):
		in_puz_lvr_2 = true
		player = body
		
		
func _on_body_glass1_entered(body):
	if body.is_in_group("player"):
		in_glass1 = true
		player = body
		
func _on_body_glass2_entered(body):
	if body.is_in_group("player"):
		in_glass2 = true
		player = body
		
func _on_body_door_entered(body):
	if body.is_in_group("player"):
		in_door = true
		player = body
	
func _on_body_ladder_entered(body):
	if body.is_in_group("player"):
		in_ladder = true
		player = body
		

func _on_lvr1_body_exited(body):
	in_lever1 = false
func _on_lvr2_body_exited(body):
	in_lever2 = false
func _on_lvr3_body_exited(body):
	in_lever3 = false
func _on_pzl_lvr1_body_exited(body):
	in_puz_lvr_1 = false
func _on_pzl_lvr2_body_exited(body):
	in_puz_lvr_2 = false
func _on_pzl_lvr3_body_exited(body):
	in_puz_lvr_3 = false
func _on_glass1_body_exited(body):
	in_glass1 = false
func _on_glass2_body_exited(body):
	in_glass2 = false
func _on_door_body_exited(body):
	in_door = false
func _on_ladder_body_exited(body):
	in_ladder = false
