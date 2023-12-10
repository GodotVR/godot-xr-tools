@tool
class_name XRToolsInteractableHingeOrigin
extends Node3D


## XR Tools Interactable Hinge Origin script
##
## The interactable hinge origin is parent of an [XRToolsInteractableHinge] node
## and defines the extent of travel the hinge can move throught.


## Hinge minimum limit (degrees)
@export var limit_minimum : float = -45.0: set = set_limit_minimum

## Hinge maximum limit (degrees)
@export var limit_maximum : float = 45.0: set = set_limit_maximum


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableHingeOrigin"


# Check for configuration warnings
func _get_configuration_warnings() -> PackedStringArray:
	var ret := PackedStringArray()

	# Check for invalid limits
	if limit_maximum <= limit_minimum:
		ret.append("Invalid hinge range")

	# Check for a hinge child
	if get_children().all(
		func(n : Node) : return not n is XRToolsInteractableHinge):
		ret.append("Missing XRToolsInteractableHinge child")

	return ret


# Handle setting the minimum limit
func set_limit_minimum(p_limit_minimum : float) -> void:
	limit_minimum = p_limit_minimum
	update_configuration_warnings()
	update_gizmos()


# Handle setting the maximum limit
func set_limit_maximum(p_limit_maximum : float) -> void:
	limit_maximum = p_limit_maximum
	update_configuration_warnings()
	update_gizmos()
