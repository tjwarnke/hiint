extends Node2D

var light1 = null
var light2 = null
var code = null
func _ready():
	light1 = get_node("MidgroundTilemap/Chandalier/PointLight2D")
	light2 = get_node("MidgroundTilemap/Chandalier2/PointLight2D")
	code = get_node("Code")
	code.hide()
	light2.hide()
	
	
func show_light():
	light2.show()
	code.show()
	
	
	
