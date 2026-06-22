@tool
class_name XRToolsMovementSprint
extends XRToolsMovementProvider

## XR Tools Movement Provider for Sprinting
##
## This script provides sprinting movement for the player. It assumes there is
## a direct movement node in the scene, otherwise it will not be functional.
##
## There will not be an error, but there will not be any reason for it to
## have any impact on the player. This node should be a direct child of
## the [XROrigin3D] node, rather than a specific [XRController3D].


## Emitted when sprinting starts
signal sprinting_started()

## Emitted when sprinting finishes
signal sprinting_finished()


## Enumeration of controller to use for triggering sprinting.  This allows the
## developer to assign the sprint button to either controller.
enum SprintController {
	LEFT,		## Use left controller
	RIGHT,		## Use right controller
}

## Enumeration of sprinting modes - toggle or hold button
enum SprintType {
	HOLD_TO_SPRINT,	## Hold button to sprint
	TOGGLE_SPRINT,	## Toggle sprinting on button press
}


## Type of sprinting
@export var sprint_type := SprintType.HOLD_TO_SPRINT

## Sprint multiplier of speed set by direct movement node(s)
@export_range(1.0, 4.0, 1.0, "or_less", "or_greater") var sprint_speed_multiplier := 2.0

## Order in which movement is processed
@export var order: int = 11

## Controller can activate sprinting
@export var controller := SprintController.LEFT

## Input action that activates sprinting
@export var sprint_button := "primary_click"


# Sprint controller
var _controller: XRController3D

# Sprint button down state
var _sprint_button_down := false

# Holds left controller's direct movement node's original max speed
var _left_controller_original_max_speed := 0.0

# Holds right controller's direct movement node's original max speed
var _right_controller_original_max_speed := 0.0


# Caches left controller's direct movement function, if any
@onready var _left_controller_direct_move := XRToolsMovementDirect.find_left(self)

# Caches right controller's direct movement function, if any
@onready var _right_controller_direct_move := XRToolsMovementDirect.find_right(self)


func _ready() -> void:
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Get the sprinting controller
	if controller == SprintController.LEFT:
		_controller = XRHelpers.get_left_controller(self)
	else:
		_controller = XRHelpers.get_right_controller(self)


# Verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Make sure player has at least one direct movement node
	if (
			not XRToolsMovementDirect.find_left(self)
			and not XRToolsMovementDirect.find_right(self)
	):
		warnings.append("Player missing XRToolsMovementDirect nodes")

	# Return warnings
	return warnings


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsMovementSprint" or super(xr_name)


## Performs sprinting
func physics_movement(
		_delta: float,
		_player_body: XRToolsPlayerBody,
		disabled: bool,
) -> bool:
	# Skip if the controller isn't active or is not enabled
	if not _controller.get_is_active() or disabled == true or not enabled:
		set_sprinting(false)
		return false

	# Detect sprint button down and pressed states
	var is_sprint_button_down := _controller.is_button_pressed(sprint_button)
	var sprint_button_pressed := (
			is_sprint_button_down
			and not _sprint_button_down
	)
	_sprint_button_down = is_sprint_button_down

	# Calculate new sprinting state
	var sprinting := is_active
	match sprint_type:
		SprintType.HOLD_TO_SPRINT:
			# Sprint when button down
			sprinting = is_sprint_button_down

		SprintType.TOGGLE_SPRINT:
			# Toggle when button pressed
			if sprint_button_pressed:
				sprinting = not sprinting

	# Update sprinting state
	if sprinting != is_active:
		set_sprinting(sprinting)

	return false


# Toggles sprinting
func set_sprinting(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update state
	is_active = active

	# Handle state change
	if is_active:
		# We are sprinting
		sprinting_started.emit()

		# Since max speeds could be changed while game is running, check
		# now for original max speeds of left and right nodes
		if _left_controller_direct_move:
			_left_controller_original_max_speed = _left_controller_direct_move.max_speed
		if _right_controller_direct_move:
			_right_controller_original_max_speed = _right_controller_direct_move.max_speed

		# Set both controllers' direct movement functions, if appliable, to
		# the sprinting speed
		if _left_controller_direct_move:
			_left_controller_direct_move.max_speed = \
					_left_controller_original_max_speed * sprint_speed_multiplier
		if _right_controller_direct_move:
			_right_controller_direct_move.max_speed = \
					_right_controller_original_max_speed * sprint_speed_multiplier
	else:
		# We are not sprinting
		sprinting_finished.emit()

		# Set both controllers' direct movement functions, if applicable, to
		# their original speeds
		if _left_controller_direct_move:
			_left_controller_direct_move.max_speed = _left_controller_original_max_speed
		if _right_controller_direct_move:
			_right_controller_direct_move.max_speed = _right_controller_original_max_speed
