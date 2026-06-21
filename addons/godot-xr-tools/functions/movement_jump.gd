@tool
class_name XRToolsMovementJump
extends XRToolsMovementProvider

## XR Tools Movement Provider for Jumping
##
## This script provides jumping mechanics for the player. This script works
## with the [XRToolsPlayerBody] attached to the player's [XROrigin3D].
##
## The player enables jumping by attaching an [XRToolsMovementJump] as a
## child of the appropriate [XRController3D], then configuring the jump button
## and jump velocity.


## Order which movement is processed
@export var order: int = 20

## Input action to trigger jump
@export var jump_button_action := "trigger_click"


# The player's [XRController3D]
var _controller: XRController3D


# When our node is added to our scene tree
func _enter_tree() -> void:
	_controller = XRHelpers.get_xr_controller(self)


# When our node is removed from our scene tree
func _exit_tree() -> void:
	_controller = null


# Verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Check the controller node
	if not XRHelpers.get_xr_controller(self):
		warnings.append("This node must be within a branch of an XRController3D node")

	# Return warnings
	return warnings


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsMovementJump" or super(xr_name)


## Performs jump movement
func physics_movement(
		_delta: float,
		player_body: XRToolsPlayerBody,
		_disabled: bool,
) -> bool:
	# Skip if the jump controller isn't active
	if not _controller or not _controller.get_is_active():
		return false

	# Request jump if the button is pressed
	if _controller.is_button_pressed(jump_button_action):
		player_body.request_jump()

	return false
