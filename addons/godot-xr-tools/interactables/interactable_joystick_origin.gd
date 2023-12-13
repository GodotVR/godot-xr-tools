@tool
class_name XRToolsInteractableJoystickOrigin
extends Node3D


## XR Tools Interactable Joystick Origin script
##
## The interactable slider origin is parent of an [XRToolsInteractableJoystick]
## node and defines the extent of travel the joystick can move throught.


## Joystick X minimum limit
@export var limit_x_minimum : float = -45.0: set = set_limit_x_minimum

## Joystick X maximum limit
@export var limit_x_maximum : float = 45.0: set = set_limit_x_maximum

## Joystick Y minimum limit
@export var limit_y_minimum : float = -45.0: set = set_limit_y_minimum

## Joystick Y maximum limit
@export var limit_y_maximum : float = 45.0: set = set_limit_y_maximum


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableJoystickOrigin"


# Check for configuration warnings
func _get_configuration_warnings() -> PackedStringArray:
	var ret := PackedStringArray()

	# Check for invalid X limits
	if limit_x_maximum <= limit_x_minimum:
		ret.append("Invalid joystick X range")

	# Check for invalid Y limits
	if limit_y_maximum <= limit_y_minimum:
		ret.append("Invalid joystick Y range")

	# Check for a hinge child
	if get_children().all(
		func(n : Node) : return not n is XRToolsInteractableJoystick):
		ret.append("Missing XRToolsInteractableJoystick child")

	return ret


# Handle setting the minimum X limit
func set_limit_x_minimum(p_limit_x_minimum : float) -> void:
	limit_x_minimum = p_limit_x_minimum
	update_configuration_warnings()
	update_gizmos()


# Handle setting the maximum X limit
func set_limit_x_maximum(p_limit_x_maximum : float) -> void:
	limit_x_maximum = p_limit_x_maximum
	update_configuration_warnings()
	update_gizmos()


# Handle setting the minimum Y limit
func set_limit_y_minimum(p_limit_y_minimum : float) -> void:
	limit_y_minimum = p_limit_y_minimum
	update_configuration_warnings()
	update_gizmos()


# Handle setting the maximum Y limit
func set_limit_y_maximum(p_limit_y_maximum : float) -> void:
	limit_y_maximum = p_limit_y_maximum
	update_configuration_warnings()
	update_gizmos()
