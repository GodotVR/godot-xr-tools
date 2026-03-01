@tool
class_name XRToolsDesktopMovementSprint
extends XRToolsMovementProvider

## XR Tools Movement Provider for Sprinting
##
## This script provides sprinting movement for the player. It assumes there is
## a direct movement node in the scene otherwise it will not be functional.
##
## There will not be an error, there just will not be any reason for it to
## have any impact on the player.  This node should be a direct child of
## the [XROrigin3D] node rather than to a specific [XRController3D].


## Emitted when sprinting starts
signal sprinting_started()

## Emitted when sprinting finishes
signal sprinting_finished()


## Enumeration of sprinting modes - toggle or hold button
enum SprintType {
	HOLD_TO_SPRINT,	## Hold button to sprint
	TOGGLE_SPRINT,	## Toggle sprinting on button press
}


## Type of sprinting
@export var sprint_type: SprintType = SprintType.HOLD_TO_SPRINT

## Sprint speed multiplier (multiplier from speed set by direct movement node(s))
@export_range(1.0, 4.0) var sprint_speed_multiplier: float = 2.0

## Movement provider order
@export var order: int = 11

## Input action for sprinting
@export var sprint_button: String = "action_sprint"


# Whether the sprint button is held down
var _sprint_button_down: bool = false

# Direct movement node's original max speed
var _direct_original_max_speed: float = 0.0


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

# Direct movement node, if any
@onready var _desktop_direct_move := XRToolsDesktopMovementDirect.find(self)


## Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsDesktopMovementSprint" or super(xr_name)


## Perform sprinting
func physics_movement(
		_delta: float,
		player_body: XRToolsPlayerBody,
		disabled: bool,
) -> void:
	# Skip if the controller isn't active or is not enabled
	if (
			not player_body.enabled
			or xr_start_node.is_xr_active()
			or disabled
			or not enabled
	):
		set_sprinting(false)
		return

	# Detect sprint button down and pressed states
	var sprint_button_down := Input.is_action_pressed(sprint_button)
	var sprint_button_pressed := sprint_button_down and not _sprint_button_down
	_sprint_button_down = sprint_button_down

	# Calculate new sprinting state
	var sprinting := is_active
	match sprint_type:
		SprintType.HOLD_TO_SPRINT:
			# Sprint when button down
			sprinting = sprint_button_down

		SprintType.TOGGLE_SPRINT:
			# Toggle when button pressed
			if sprint_button_pressed:
				sprinting = not sprinting

	# Update sprinting state
	if sprinting != is_active:
		set_sprinting(sprinting)


## Toggles sprinting
func set_sprinting(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update state
	is_active = active

	# Handle state change
	if is_active:
		# If we are sprinting
		sprinting_started.emit()

		# Since max speeds could be changed while game is running, check
		# now for original max speeds of left and right nodes
		if _desktop_direct_move:
			_direct_original_max_speed = _desktop_direct_move.max_speed

		# Set both controllers' direct movement functions, if appliable, to
		# the sprinting speed
		if _desktop_direct_move:
			_desktop_direct_move.max_speed = \
					_direct_original_max_speed * sprint_speed_multiplier
	else:
		# If we are not sprinting
		sprinting_finished.emit()

		# Set both controllers' direct movement functions, if applicable, to
		# their original speeds
		if _desktop_direct_move:
			_desktop_direct_move.max_speed = _direct_original_max_speed


# Verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Make sure player has at least one direct movement node
	if not XRToolsDesktopMovementDirect.find(self):
		warnings.append("Player missing XRToolsDesktopMovementDirect node")

	# Return warnings
	return warnings
