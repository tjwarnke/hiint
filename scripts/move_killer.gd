extends Area2D

@export var npc: Node2D  # or Killer if you used class_name

func _on_body_entered(body):
	if body.name == "Player":
		if npc != null and npc.has_method("start_moving"):
			npc.start_moving()
