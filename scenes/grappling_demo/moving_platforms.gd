extends Node3D

# Rotation rate
const RATE = 10.0 * PI / 180.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	rotate_y(delta * RATE)
