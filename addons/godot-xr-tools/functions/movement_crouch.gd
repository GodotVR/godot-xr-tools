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
@export var order: int = 10

## Player height when crouching
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var crouch_height := 1.0

## Crouch button
@export var crouch_button_action := "primary_click"

## Type of crouching
@export var crouch_type := CrouchType.HOLD_TO_CROUCH


# Whether the player is currently crouching
var _crouching := false

# Whether the player is trying to crouch
var _crouch_button_down := false

# Controller node
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
	return xr_name == "XRToolsMovementCrouch" or super(xr_name)


## Performs crouch movement
func physics_movement(
		_delta: float,
		player_body: XRToolsPlayerBody,
		_disabled: bool,
) -> bool:
	# Skip if the controller isn't active
	if not _controller or not _controller.get_is_active():
		return false

	# Detect crouch button down and pressed states
	var is_crouch_button_down := _controller.is_button_pressed(crouch_button_action)
	var crouch_button_pressed := is_crouch_button_down and not _crouch_button_down
	_crouch_button_down = is_crouch_button_down

	# Calculate new crouching state
	var crouching := _crouching
	match crouch_type:
		CrouchType.HOLD_TO_CROUCH:
			# Crouch when button down
			crouching = is_crouch_button_down

		CrouchType.TOGGLE_CROUCH:
			# Toggle when button pressed
			if crouch_button_pressed:
				crouching = not crouching

	# Update crouching state
	if crouching != _crouching:
		_crouching = crouching
		if crouching:
			player_body.override_player_height(self, crouch_height)
		else:
			player_body.override_player_height(self)

	return false
