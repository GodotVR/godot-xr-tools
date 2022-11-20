tool
class_name XRToolsMovementTurn
extends XRToolsMovementProvider

##
## Movement Provider for Turning
##
## @desc:
##     This script provides turning support for the player. This script works
##     with the PlayerBody attached to the players ARVROrigin.
##
##     The following types of turning are supported:
##      - Snap turning
##      - Smooth turning
##


## Movement provider order
export var order : int = 5

## Movement mode
enum TurnMode {
	DEFAULT,
	SNAP,
	SMOOTH
}

export (TurnMode) var turn_mode = TurnMode.DEFAULT

## Smooth turn speed in radians per second
export var smooth_turn_speed : float = 2.0

## Seconds per step (at maximum turn rate)
export var step_turn_delay : float = 0.2

## Step turn angle in degrees
export var step_turn_angle : float = 20.0


# Turn step accumulator
var _turn_step : float = 0.0


# Controller node
onready var _controller := ARVRHelpers.get_arvr_controller(self)


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsMovementTurn" or .is_class(name)


# Perform jump movement
func physics_movement(delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	var deadzone = 0.1
	if _snap_turning():
		deadzone = XRTools.get_snap_turning_deadzone()

	# Read the left/right joystick axis
	var left_right := _controller.get_joystick_axis(XRTools.Axis.VR_PRIMARY_X_AXIS)
	if abs(left_right) <= deadzone:
		# Not turning
		_turn_step = 0.0
		return

	# Handle smooth rotation
	if !_snap_turning():
		_rotate_player(player_body, smooth_turn_speed * delta * left_right)
		return

	# Update the next turn-step delay
	_turn_step -= abs(left_right) * delta
	if _turn_step >= 0.0:
		return

	# Turn one step in the requested direction
	_turn_step = step_turn_delay
	_rotate_player(player_body, deg2rad(step_turn_angle) * sign(left_right))


# Rotate the origin node around the camera
func _rotate_player(player_body: XRToolsPlayerBody, angle: float):
	var t1 := Transform()
	var t2 := Transform()
	var rot := Transform()

	t1.origin = -player_body.camera_node.transform.origin
	t2.origin = player_body.camera_node.transform.origin
	rot = rot.rotated(Vector3(0.0, -1.0, 0.0), angle)
	player_body.origin_node.transform = (player_body.origin_node.transform * t2 * rot * t1).orthonormalized()


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	if !ARVRHelpers.get_arvr_controller(self):
		return "Unable to find ARVR Controller node"

	# Call base class
	return ._get_configuration_warning()


func _snap_turning():
	if turn_mode == TurnMode.SNAP:
		return true
	elif turn_mode == TurnMode.SMOOTH:
		return false
	else:
		return XRToolsUserSettings.snap_turning
