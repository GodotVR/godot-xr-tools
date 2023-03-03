@tool
class_name XRToolsInteractableArea
extends Area3D


signal pointer_pressed(at)
signal pointer_released(at)
signal pointer_moved(from, to)
signal pointer_entered()
signal pointer_exited()


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableArea"
