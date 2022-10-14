extends Node3D

# Rotation rate
@export var rate : float = 10.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	rotate_y(deg_to_rad(delta * rate))
