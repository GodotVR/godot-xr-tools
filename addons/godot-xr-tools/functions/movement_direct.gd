@tool
class_name XRToolsMovementDirect
extends XRToolsMovementProvider

## XR Tools Movement Provider for Direct Movement
##
## This script provides direct movement for the player. This script works
## with the [XRToolsPlayerBody] attached to the players [XROrigin3D].
##
## The player may have multiple [XRToolsMovementDirect] nodes attached to
## different controllers to provide different types of direct movement.


## Order in which movement is processed
@export var order: int = 10

## Movement speed
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var max_speed := 3.0

## Whether the player can strafe
@export var strafe := false

## Input action for movement direction
@export var input_action := "primary"


# Controller node
var _controller: XRController3D


## Finds the left [XRToolsMovementDirect] node.
##
## This function searches from the specified node for the left controller
## [XRToolsMovementDirect] assuming the node is a sibling of the [XROrigin3D].
static func find_left(node: Node) -> XRToolsMovementDirect:
	return XRTools.find_xr_child(
			XRHelpers.get_left_controller(node),
			"*",
			"XRToolsMovementDirect",
	) as XRToolsMovementDirect


## Finds the right [XRToolsMovementDirect] node.
##
## This function searches from the specified node for the right controller
## [XRToolsMovementDirect] assuming the node is a sibling of the [XROrigin3D].
static func find_right(node: Node) -> XRToolsMovementDirect:
	return XRTools.find_xr_child(
			XRHelpers.get_right_controller(node),
			"*",
			"XRToolsMovementDirect",
	) as XRToolsMovementDirect


# When our node is added to our scene tree
func _enter_tree() -> void:
	_controller = XRHelpers.get_xr_controller(self)


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Check the controller node
	if not XRHelpers.get_xr_controller(self):
		warnings.append("This node must be within a branch of an XRController3D node")

	# Return warnings
	return warnings


# When our node is removed from our scene tree
func _exit_tree() -> void:
	_controller = null


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsMovementDirect" or super(xr_name)


## Performs jump movement
func physics_movement(
		_delta: float,
		player_body: XRToolsPlayerBody,
		_disabled: bool,
) -> bool:
	# Skip if the controller isn't active
	if not _controller or not _controller.get_is_active():
		return false

	# Get input action with deadzone correction applied
	var dz_input_action: Vector2 = XRToolsUserSettings.get_adjusted_vector2(
			_controller,
			input_action,
	)

	player_body.ground_control_velocity.y += dz_input_action.y * max_speed
	if strafe:
		player_body.ground_control_velocity.x += dz_input_action.x * max_speed

	# Clamp ground control
	var length := player_body.ground_control_velocity.length()
	if length > max_speed:
		player_body.ground_control_velocity *= max_speed / length

	return false
