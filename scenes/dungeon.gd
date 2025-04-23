extends Node2D

var door
var doors
var glass1
var hammer
var lever1
var lever2
var lever3
var key
var cageDoor1
var cageDoor2
var trapdoor
var ladder

var puz_lvr_1
var puz_lvr_2
var puz_lvr_3

var in_puz_lvr_1 = false
var in_puz_lvr_2 = false
var in_puz_lvr_3 = false

var in_lever1 = false
var in_lever2 = false
var in_lever3 = false
var in_glass1 = false
var in_door = false
var in_ladder = false

var checkPuz1 = true
var checkPuz2 = false 
var checkPuz3 = false

var player

func _ready():
	door = get_node("Door")
	doors = get_node("Doors")
	glass1 = get_node("Glass1")
	hammer = get_node("Hammer")
	lever1 = get_node("Lever")
	lever2 = get_node("Lever2")
	lever3 = get_node("Lever3")
	key = get_node("Key")
	cageDoor1 = get_node("CageDoor1")
	cageDoor2 = get_node("CageDoor2")
	player = get_node_or_null("/root/World/Player")
	puz_lvr_1 = get_node("PuzzleLever1")
	puz_lvr_2 = get_node("PuzzleLever2")
	puz_lvr_3 = get_node("PuzzleLever3")
	trapdoor = get_node("Trapdoor")
	ladder = get_node("Ladder")
	
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
	
func open_door():
	door.hide()
	#TODO: play a sound

func check_puzzle():
	if checkPuz1 and checkPuz2 and checkPuz3:
		trapdoor.hide()
		
func climb_ladder():
	#TODO: change scene back to dining room and play final cutscene
	pass
