@tool
class_name XRToolsDesktopMovementTurn
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
@export var order : int = 6

## Movement mode property
@export var turn_mode : TurnMode = TurnMode.SMOOTH

## Smooth turn speed in radians per second
@export var smooth_turn_speed : float = 2.0

## Seconds per step (at maximum turn rate)
@export var step_turn_delay : float = 0.2

## Step turn angle in degrees
@export var step_turn_angle : float = 20.0

## Our directional input
@export var input_action : String = "primary"

## Our directional input
@export var clear_mouse_move_when_body_not_active : bool = true


@export var invert_y : bool = true

# Turn step accumulator
var _turn_step : float = 0.0


# XRStart node
@onready var XRStartNode = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,
	"*Staging",
	"XRToolsStaging"),"StartXR","Node")


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsDesktopMovementTurn" or super(name)

var mouse_move_vector := Vector2.ZERO
func _unhandled_input(event):
	if !enabled:
		return
	if event is InputEventMouseMotion:
		event.relative*=.1
		if invert_y:
			event.relative.y *= -1
		mouse_move_vector += event.relative

# Perform jump movement
func physics_movement(delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the player body isn't active
	if !player_body.enabled or XRStartNode.xr_active:
		if clear_mouse_move_when_body_not_active:
			mouse_move_vector=Vector2.ZERO
		return

	var deadzone = 0.1
#	if _snap_turning():
#		deadzone = XRTools.get_snap_turning_deadzone()

	# Read the left/right joystick axis
	var left_right := mouse_move_vector.x
	if abs(left_right) <= deadzone:
		# Not turning
		_turn_step = 0.0
		return

	# Handle smooth rotation
	#if !_snap_turning():
	left_right -= deadzone * sign(left_right)
	player_body.rotate_player(smooth_turn_speed * delta * left_right)
	player_body.camera_node.rotation_degrees.x=clamp(
		player_body.camera_node.rotation_degrees.x+mouse_move_vector.y,
		-89.999,
		89.999)
	mouse_move_vector=Vector2.ZERO
	return



# Test if snap turning should be used
func _snap_turning():
	#temp removal - IDK if normal controler will be considered t ohave this as use
	return false
#	match turn_mode:
#		TurnMode.SNAP:
#			return true
#
#		TurnMode.SMOOTH:
#			return false
#
#		_:
#			return XRToolsUserSettings.snap_turning
