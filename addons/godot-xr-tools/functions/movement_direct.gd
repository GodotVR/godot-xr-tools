tool
class_name XRToolsMovementDirect
extends XRToolsMovementProvider


## XR Tools Movement Provider for Direct Movement
##
## This script provides direct movement for the player. This script works
## with the [XRToolsPlayerBody] attached to the players [ARVROrigin].
##
## The player may have multiple [XRToolsMovementDirect] nodes attached to
## different controllers to provide different types of direct movement.


## Movement provider order
export var order : int = 10

## Movement speed
export var max_speed : float = 10.0

## If true, the player can strafe
export var strafe : bool = false


# Controller node
onready var _controller := ARVRHelpers.get_arvr_controller(self)


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsMovementDirect" or .is_class(name)


# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	# Apply forwards/backwards ground control
	player_body.ground_control_velocity.y += _controller.get_joystick_axis(
			XRTools.Axis.VR_PRIMARY_Y_AXIS) * max_speed

	# Apply left/right ground control
	if strafe:
		player_body.ground_control_velocity.x += _controller.get_joystick_axis(
				XRTools.Axis.VR_PRIMARY_X_AXIS) * max_speed

	# Clamp ground control
	var length := player_body.ground_control_velocity.length()
	if length > max_speed:
		player_body.ground_control_velocity *= max_speed / length


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	if !ARVRHelpers.get_arvr_controller(self):
		return "This node must be within a branch of an ARVRController node"

	# Call base class
	return ._get_configuration_warning()


## Find the left [XRToolsMovementDirect] node.
##
## This function searches from the specified node for the left controller
## [XRToolsMovementDirect] assuming the node is a sibling of the [ARVROrigin].
static func find_left(node : Node) -> XRToolsMovementDirect:
	return XRTools.find_child(
		ARVRHelpers.get_left_controller(node),
		"*",
		"XRToolsMovementDirect") as XRToolsMovementDirect


## Find the right [XRToolsMovementDirect] node.
##
## This function searches from the specified node for the right controller
## [XRToolsMovementDirect] assuming the node is a sibling of the [ARVROrigin].
static func find_right(node : Node) -> XRToolsMovementDirect:
	return XRTools.find_child(
		ARVRHelpers.get_right_controller(node),
		"*",
		"XRToolsMovementDirect") as XRToolsMovementDirect
