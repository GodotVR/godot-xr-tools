@tool
class_name XRToolsWindArea
extends Area3D

## Vector (direction and magnitude) of wind in this area
@export var wind_vector : Vector3 = Vector3.ZERO

## Wind drag factor
@export var drag : float = 1.0


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsWindArea"
