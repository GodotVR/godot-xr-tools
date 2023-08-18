@tool
class_name XRToolsInteractableArea
extends Area3D


## Signal when pointer event occurs on area
signal pointer_event(event)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableArea"
