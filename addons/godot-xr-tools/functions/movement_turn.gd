@tool
class_name XRToolsMovementTurn
extends XRToolsMovementProvider


## XR Tools Movement Provider for Turning
##
## This script provides turning support for the player. This script works
## with the PlayerBody attached to the players XROrigin3D.


## Movement mode
enum TurnMode {
	DEFAULT,	## Use turn mode from project/user settings
	SNAP,		## Use snap-turning
	SMOOTH		## Use smooth-turning
}


## Movement provider order
@export var order : int = 5

## Movement mode property
@export var turn_mode : TurnMode = TurnMode.DEFAULT

## Smooth turn speed in radians per second
@export var smooth_turn_speed : float = 2.0

## Seconds per step (at maximum turn rate)
@export var step_turn_delay : float = 0.2

## Step turn angle in degrees
@export var step_turn_angle : float = 20.0

## Our directional input
@export var input_action : String = "primary"

# Turn step accumulator
var _turn_step : float = 0.0


# Controller node
var _controller : XRController3D


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsMovementTurn" or super(xr_name)


# Called when our node is added to our scene tree
func _enter_tree():
	_controller = XRHelpers.get_xr_controller(self)


# Called when our node is removed from our scene tree
func _exit_tree():
	_controller = null


# Perform jump movement
func physics_movement(delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if not _controller or not _controller.get_is_active():
		return

	var deadzone = 0.1
	if _snap_turning():
		deadzone = XRTools.get_snap_turning_deadzone()

	# Read the left/right joystick axis
	var left_right := _controller.get_vector2(input_action).x
	if abs(left_right) <= deadzone:
		# Not turning
		_turn_step = 0.0
		return

	# Handle smooth rotation
	if !_snap_turning():
		left_right -= deadzone * sign(left_right)
		player_body.rotate_player(smooth_turn_speed * delta * left_right)
		return

	# Disable repeat snap turning if delay is zero
	if step_turn_delay == 0.0 and _turn_step < 0.0:
		return

	# Update the next turn-step delay
	_turn_step -= abs(left_right) * delta
	if _turn_step >= 0.0:
		return

	# Turn one step in the requested direction
	if step_turn_delay != 0.0:
		_turn_step = step_turn_delay

	player_body.rotate_player(deg_to_rad(step_turn_angle) * sign(left_right))


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Check the controller node
	if not XRHelpers.get_xr_controller(self):
		warnings.append("Unable to find XRController3D node")

	# Return warnings
	return warnings


# Test if snap turning should be used
func _snap_turning():
	match turn_mode:
		TurnMode.SNAP:
			return true

		TurnMode.SMOOTH:
			return false

		_:
			return XRToolsUserSettings.snap_turning
