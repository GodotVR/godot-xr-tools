tool
class_name XRToolsWindArea
extends Area

## Vector (direction and magnitude) of wind in this area
export var wind_vector : Vector3 = Vector3.ZERO

## Wind drag factor
export var drag : float = 1.0


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsWindArea" or .is_class(name)
