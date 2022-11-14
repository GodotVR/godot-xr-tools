tool
class_name XRToolsMovementSprint
extends XRToolsMovementProvider


##
## XR Tools Movement Provider for Sprinting
##
##     This script provides sprinting movement for the player. It assumes there is a direct movement
##	   node in the scene otherwise it will not be functional. There will not be an error, there just
##	   will not be any reason for it to have any impact on the player.  This node should be a direct
##	   child of the FPController node rather than to a specific ARVRController.


## Signal emitted when sprinting starts
signal sprinting_started()

## Signal emitted when sprinting finishes
signal sprinting_finished()


## Enumeration of controller to use for triggering sprinting.  This allows the developer to assign the sprint button to either controller
enum SprintController {
	LEFT,		# Use left controller
	RIGHT,		# Use right controler
}

## Enumeration of sprinting modes - toggle or hold button
enum SprintType {
	HOLD_TO_SPRINT,	## Hold button to sprint
	TOGGLE_SPRINT,	## Toggle sprinting on button press
}

## Type of sprinting
export (SprintType) var sprint_type : int = SprintType.HOLD_TO_SPRINT

## Sprint speed multiplier (multiplier from speed set by direct movement node(s))
export (float, 1.0, 4.0) var sprint_speed_multiplier : float = 2.0

## Movement provider order
export var order : int = 11

## Sprint controller
export (SprintController) var controller : int = SprintController.LEFT

## Sprint button
export (XRTools.Buttons) var sprint_button : int = XRTools.Buttons.VR_PAD

# Sprint controller
var _controller : ARVRController

## Sprinting flag
var _sprinting : bool = false

## Sprint button down state
var _sprint_button_down : bool = false

## Variable to hold left controller direct movement node max speed if any
var _left_controller_max_speed : float = 0.0

## Variable to hold left controller direct movement node original max speed
var _left_controller_original_max_speed : float = 0.0

## Variable to hold right controller direct movement node max speed if any
var _right_controller_max_speed : float = 0.0

## Variable to hold right controller direct movement node original max speed
var _right_controller_original_max_speed : float = 0.0

## Variable to hold overall max speed between direct movement nodes if multiple
var _overall_max_speed : float = 0.0

## Fetch left controller
onready var _left_controller : ARVRController = ARVRHelpers.get_left_controller(self)

## Fetch right controller
onready var _right_controller : ARVRController = ARVRHelpers.get_right_controller(self)

## Fetch left controller direct movement function if any using XRTools' ARVRHelpers function
onready var _left_controller_direct_move : XRToolsMovementDirect = ARVRHelpers.find_child(_left_controller, "*", "XRToolsMovementDirect")

## Fetch right controller direct movement function if any using XRTools' ARVRHelpers function
onready var _right_controller_direct_move : XRToolsMovementDirect = ARVRHelpers.find_child(_right_controller, "*", "XRToolsMovementDirect")

func _ready():
	# Get the sprinting controller
	if controller == SprintController.LEFT:
		_controller = _left_controller
	else:
		_controller = _right_controller

	# If no direct movement node found, do not execute further, no speed to sprint at
	if _left_controller_direct_move == null and _right_controller_direct_move == null:
		return
	
	# Capture original max move speeds for left and right controller direct movement nodes, if any	
	if _left_controller_direct_move != null:
		_left_controller_original_max_speed = _left_controller_direct_move.max_speed
	if _right_controller_direct_move != null:
		_right_controller_original_max_speed = _right_controller_direct_move.max_speed
	
	# Set overall max speed to highest of left and right controllers, if any
	if _left_controller_original_max_speed >= _right_controller_original_max_speed:
		_overall_max_speed = _left_controller_original_max_speed
	else:
		_overall_max_speed = _right_controller_original_max_speed

# Perform sprinting
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Skip if the controller isn't active or is not enabled 
	if !_controller.get_is_active() or disabled == true or !enabled:
		set_sprinting(false)
		return
	
	# Get present state of left and right movement nodes, since nodes can be removed or made inactive while game is running
	_left_controller_direct_move = ARVRHelpers.find_child(_left_controller, "*", "XRToolsMovementDirect")
	_right_controller_direct_move = ARVRHelpers.find_child(_right_controller, "*", "XRToolsMovementDirect")
	
	# If no direct movement node found or both direct movement nodes are disabled, do not execute further, no speed to sprint
	if (_left_controller_direct_move == null and _right_controller_direct_move == null) or (_left_controller_direct_move.enabled == false and _right_controller_direct_move.enabled == false):
		return
	
	# Since max speeds could be changed while game is running, check again for max speeds of left and right nodes	
	if _left_controller_direct_move != null and _left_controller_direct_move.enabled == true:
		_left_controller_max_speed = _left_controller_direct_move.max_speed
	if _right_controller_direct_move != null and _right_controller_direct_move.enabled == true:
		_right_controller_max_speed = _right_controller_direct_move.max_speed
	
	# Set overall max speed based on current status during runtime
	if _left_controller_max_speed >= _right_controller_max_speed:
		_overall_max_speed = _left_controller_max_speed
	else:
		_overall_max_speed = _right_controller_max_speed	
		
	# Detect sprint button down and pressed states
	var sprint_button_down := _controller.is_button_pressed(sprint_button) != 0
	var sprint_button_pressed := sprint_button_down and !_sprint_button_down
	_sprint_button_down = sprint_button_down

	# Calculate new sprinting state
	var sprinting := _sprinting
	match sprint_type:
		SprintType.HOLD_TO_SPRINT:
			# Sprint when button down
			sprinting = sprint_button_down

		SprintType.TOGGLE_SPRINT:
			# Toggle when button pressed
			if sprint_button_pressed:
				sprinting = !sprinting

	# Update sprinting state
	if sprinting != _sprinting:
		_sprinting = sprinting
		if sprinting:
			set_sprinting(true)
		else:
			set_sprinting(false)
			

func set_sprinting(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update state
	is_active = active

	# Handle state change
	if is_active:
		emit_signal("sprinting_started")
		_sprinting = true
		# Set both controllers' direct movement functions, if appliable, to the sprinting speed
		if _left_controller_direct_move != null:
			_left_controller_direct_move.max_speed = _overall_max_speed*sprint_speed_multiplier
		if _right_controller_direct_move != null:
			_right_controller_direct_move.max_speed = _overall_max_speed*sprint_speed_multiplier
	else:
		emit_signal("sprinting_finished")
		_sprinting = false
		# Set both controllers' direct movement functions, if applicable, to their original speeds
		if _left_controller_direct_move != null:
			_left_controller_direct_move.max_speed = _left_controller_original_max_speed
		if _right_controller_direct_move != null:
			_right_controller_direct_move.max_speed = _right_controller_original_max_speed



# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Call base class
	return ._get_configuration_warning()
