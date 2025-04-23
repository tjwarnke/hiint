extends Node2D

var chandelierLight
var painting
var trapdoor
var lever1
var lever2
var writing
var poolTable
var safe

var in_lever1 = false
var in_lever2 = false
var in_safe = false

func _ready():
	safe = get_node("Safe")
	chandelierLight = get_node("MidgroundTilemap/Chandalier2/PointLight2D")
	painting = get_node("MidgroundTilemap/Painting")
	trapdoor = get_node("DroppingPlatform")
	lever1 = get_node("Lever1")
	lever2 = get_node("Lever2")
	writing = get_node("BloodWriting")
	poolTable = get_node("PoolTable")
	safe.hide()
	writing.hide()
	chandelierLight.hide()
	
func _input(event: InputEvent) -> void:
	if in_lever1 and event.is_action_pressed("pick_up"):
		lever1_action()
	if in_lever2 and event.is_action_pressed("pick_up"):
		lever2_action()
	if in_safe and event.is_action_pressed("pick_up"):
		safe_action()
		
func lever1_action():
	painting.hide()
	safe.show()

func lever2_action():
	chandelierLight.show()
	writing.show()
	
func safe_action():
	pass
	
