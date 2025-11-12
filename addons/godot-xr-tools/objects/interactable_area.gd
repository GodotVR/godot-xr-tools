@tool
class_name XRToolsInteractableArea
extends Area3D


## Signal when pointer event occurs on area
signal pointer_event(event)


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsInteractableArea"
