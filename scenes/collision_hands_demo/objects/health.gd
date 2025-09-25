extends Node

class_name Health

@export var current_health: int = 100

signal health_depleted
signal damage_taken


func apply_damage(d): 
	current_health -= d 

	emit_signal("damage_taken")

	if current_health <= 0: 
		emit_signal("health_depleted")
