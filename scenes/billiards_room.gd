extends Node2D

var chandelierLight
var painting
var trapdoor
var lever1
var lever2
var writing
var poolTable
var safe
var safePlatform 

var in_lever1 = false
var in_lever2 = false
var in_safe = false
func _ready():
	safe = get_node("Safe/Area2D")
	chandelierLight = get_node("MidgroundTilemap/Chandalier2/PointLight2D")
	painting = get_node("MidgroundTilemap/Painting")
	trapdoor = get_node("DroppingPlatform")
	lever1 = get_node("Lever1")
	lever2 = get_node("Lever2")
	writing = get_node("BloodWriting")
	poolTable = get_node("PoolTable")
	safePlatform = get_node("SafePlatform")
	lever1.body_entered.connect( _on_lever_1_body_entered)
	lever2.body_entered.connect( _on_lever_2_body_entered)
	safe.body_entered.connect( _on_safe_body_entered)
	lever1.body_exited.connect( _on_lever_1_body_exited)
	lever2.body_exited.connect( _on_lever_2_body_exited)
	safe.body_exited.connect( _on_safe_body_exited)
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
		
func lever1_action():
	painting.hide()
	safe.show()
	safePlatform.show()

func lever2_action():
	chandelierLight.show()
	writing.show()
	
func safe_action():
	#player has to select the numbers 10-31-84
	pass

func _on_lever_1_body_entered(body):
	in_lever1 = true
	
func _on_lever_2_body_entered(body):
	in_lever2 = true
	
func _on_safe_body_entered(body):
	in_safe = true
	
func _on_lever_1_body_exited(body):
	in_lever1 = false
	
func _on_lever_2_body_exited(body):
	in_lever2 = false
	
func _on_safe_body_exited(body):
	in_safe = false
	
