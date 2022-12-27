tool
class_name XRToolsMovementJump
extends XRToolsMovementProvider


## XR Tools Movement Provider for Jumping
##
## This script provides jumping mechanics for the player. This script works
## with the [XRToolsPlayerBody] attached to the players [ARVROrigin].
##
## The player enables jumping by attaching an [XRToolsMovementJump] as a
## child of the appropriate [ARVRController], then configuring the jump button
## and jump velocity.


## Movement provider order
export var order : int = 20

## Button to trigger jump
export (XRTools.Buttons) var jump_button_id : int = XRTools.Buttons.VR_TRIGGER


# Node references
onready var _controller := ARVRHelpers.get_arvr_controller(self)


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsMovementJump" or .is_class(name)


# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the jump controller isn't active
	if !_controller.get_is_active():
		return

	# Request jump if the button is pressed
	if _controller.is_button_pressed(jump_button_id):
		player_body.request_jump()


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	if !ARVRHelpers.get_arvr_controller(self):
		return "This node must be within a branch of an ARVRController node"

	# Call base class
	return ._get_configuration_warning()
