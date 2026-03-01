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
@export var order: int = 6

## Movement mode property
@export var turn_mode: TurnMode = TurnMode.SMOOTH

## Smooth turn speed in radians per second
@export var smooth_turn_speed: float = 2.0

## Seconds per step (at maximum turn rate)
@export var step_turn_delay: float = 0.2

## Step turn angle in degrees
@export var step_turn_angle: float = 20.0

## Input action for turning
@export var input_action: String = "primary"

## Whether to check for mouse motion when the player body is inactive
@export var clear_mouse_move_when_body_not_active: bool = true

## Whether to rotate the camera on the x-axis when the player body is inactive
@export var clear_cam_x_when_body_not_active: bool = false

## Whether to invert the vertical rotation of the camera
@export var invert_y: bool = true


## XR Player Body
var plr_body: XRToolsPlayerBody

## Motion vector of the mouse
var mouse_move_vector: Vector2 = Vector2.ZERO

# Whether the player body was previously active
var _last_plr_bd_status: bool = true

# Turn step accumulator
var _turn_step: float = 0.0


## XRStart node
@onready var xr_start_node: XRToolsStartXR = XRTools.find_xr_child(
		XRTools.find_xr_ancestor(
				self,
				"*Staging",
				"XRToolsStaging",
		),
		"StartXR",
		"Node",
)


func _process(_delta: float) -> void:
	if is_instance_valid(plr_body):
		if (
				not plr_body.enabled
				and not xr_start_node.is_xr_active()
				and _last_plr_bd_status != plr_body.enabled
		):
			if clear_mouse_move_when_body_not_active:
				mouse_move_vector = Vector2.ZERO
			if clear_cam_x_when_body_not_active:
				plr_body.camera_node.rotation_degrees.x = 0
			_last_plr_bd_status = not plr_body.enabled
		elif plr_body.enabled:
			_last_plr_bd_status = not plr_body.enabled


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return

	if event is InputEventMouseMotion:
		event.relative *= .1
		if invert_y:
			event.relative.y *= -1
		mouse_move_vector += event.relative


## Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsDesktopMovementTurn" or super(xr_name)


## Perform jump movement
func physics_movement(
		delta: float,
		player_body: XRToolsPlayerBody,
		_disabled: bool
) -> void:
	# Skip if the player body isn't active
	plr_body = player_body
	if not player_body.enabled or xr_start_node.is_xr_active():
		if clear_mouse_move_when_body_not_active:
			mouse_move_vector = Vector2.ZERO
		return

	# Read the left/right joystick axis to handle smooth rotation
	var deadzone: float = 0.1
	var left_right: float = mouse_move_vector.x
	left_right -= deadzone * sign(left_right)
	player_body.rotate_player(smooth_turn_speed * delta * left_right)
	player_body.camera_node.rotation_degrees.x = clampf(
			(
					player_body.camera_node.rotation_degrees.x
					+ smooth_turn_speed
					* mouse_move_vector.y
			),
			-89.999,
			89.999,
	)
	mouse_move_vector = Vector2.ZERO
	return


# Test if snap turning should be used
func _snap_turning() -> bool:
	#temp removal - IDK if normal controller will be considered to have this as use
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
