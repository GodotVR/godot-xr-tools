class_name XRToolsInteractableBody
extends Node3D
# This should extend from PhysicsBody3D but https://github.com/godotengine/godot/issues/46073


signal pointer_pressed(at)
signal pointer_released(at)
signal pointer_moved(from, to)
signal pointer_entered()
signal pointer_exited()
