@tool
class_name XRToolsMovementCrouch
extends XRToolsMovementProvider


## XR Tools Movement Provider for Crouching
##
## This script works with the [XRToolsPlayerBody] attached to the players
## [XROrigin3D].
##
## While the player presses the crounch button, the height is overridden to
## the specified crouch height.


## Enumeration of crouching modes
enum CrouchType {
	HOLD_TO_CROUCH,	## Hold button to crouch
	TOGGLE_CROUCH,	## Toggle crouching on button press
}


## Movement provider order
@export var order : int = 10

## Crouch height
@export var crouch_height : float = 1.0

## Crouch button
@export var crouch_button_action : String = "primary_click"

## Type of crouching
@export var crouch_type : CrouchType = CrouchType.HOLD_TO_CROUCH


## Crouching flag
var _crouching : bool = false

## Crouch button down state
var _crouch_button_down : bool = false


# Controller node
@onready var _controller := XRHelpers.get_xr_controller(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementCrouch" or super(name)


# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	# Detect crouch button down and pressed states
	var crouch_button_down := _controller.is_button_pressed(crouch_button_action)
	var crouch_button_pressed := crouch_button_down and !_crouch_button_down
	_crouch_button_down = crouch_button_down

	# Calculate new crouching state
	var crouching := _crouching
	match crouch_type:
		CrouchType.HOLD_TO_CROUCH:
			# Crouch when button down
			crouching = crouch_button_down

		CrouchType.TOGGLE_CROUCH:
			# Toggle when button pressed
			if crouch_button_pressed:
				crouching = !crouching

	# Update crouching state
	if crouching != _crouching:
		_crouching = crouching
		if crouching:
			player_body.override_player_height(self, crouch_height)
		else:
			player_body.override_player_height(self)


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Check the controller node
	if !XRHelpers.get_xr_controller(self):
		warnings.append("This node must be within a branch of an XRController3D node")

	# Return warnings
	return warnings
