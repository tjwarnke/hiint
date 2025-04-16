extends Node2D
@onready var animation_player = $AnimationPlayer
var is_on = false # Tracks the state of the lever
var player_in_range = false # Tracks if the player is close enough to interact
@onready var platform = $Platform

func _ready():
	#platform.enabled = false
	pass
	
func _input(event):
	if event.is_action_pressed("pick_up") and player_in_range:
		toggle_lever()
		
func toggle_lever():
	if is_on:
		animation_player.play("lever_off")
		platform.enabled = false
	else:
		animation_player.play("lever")
		platform.enabled = true
#
	is_on = !is_on # Toggle the state

func _on_body_entered(_body):
	player_in_range = true


func _on_body_exited(_body):
	player_in_range = false
