tool
class_name XRToolsMovementSprint
extends XRToolsMovementProvider


## XR Tools Movement Provider for Sprinting
##
## This script provides sprinting movement for the player. It assumes there is a direct movement
## node in the scene otherwise it will not be functional. There will not be an error, there just
## will not be any reason for it to have any impact on the player.  This node should be a direct
## child of the FPController node rather than to a specific ARVRController.


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

## Variable to hold left controller direct movement node original max speed
var _left_controller_original_max_speed : float = 0.0

## Variable to hold right controller direct movement node original max speed
var _right_controller_original_max_speed : float = 0.0

## Variable used to cache left controller direct movement function, if any 
var _left_controller_direct_move : XRToolsMovementDirect = null 

## Variable used to cache right controller direct movement function, if any
var _right_controller_direct_move : XRToolsMovementDirect = null

## Fetch left controller
onready var _left_controller : ARVRController = ARVRHelpers.get_left_controller(self)

## Fetch right controller
onready var _right_controller : ARVRController = ARVRHelpers.get_right_controller(self)


func _ready():
	# Get the sprinting controller
	if controller == SprintController.LEFT:
		_controller = _left_controller
	else:
		_controller = _right_controller

	# Cache the left controller direct movement node, if any
	var left_controller_nodes = _left_controller.get_children()
	for child in left_controller_nodes:
		if child is XRToolsMovementDirect:
			_left_controller_direct_move = child
			break
	
	# Cache the right controller direct movement node, if any
	var right_controller_nodes = _right_controller.get_children()
	for child in right_controller_nodes:
		if child is XRToolsMovementDirect:
			_right_controller_direct_move = child
			break
	
	
# Perform sprinting
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Skip if the controller isn't active or is not enabled 
	if !_controller.get_is_active() or disabled == true or !enabled:
		set_sprinting(false)
		return
		
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
			
			
# Public function used to set sprinting active or not active
func set_sprinting(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update state
	is_active = active

	# Handle state change
	if is_active:
		# We are sprinting
		emit_signal("sprinting_started")
		_sprinting = true
		
		# Since max speeds could be changed while game is running, check now for original max speeds of left and right nodes	
		if _left_controller_direct_move:
			_left_controller_original_max_speed = _left_controller_direct_move.max_speed
		if _right_controller_direct_move:
			_right_controller_original_max_speed = _right_controller_direct_move.max_speed
		
		# Set both controllers' direct movement functions, if appliable, to the sprinting speed
		if _left_controller_direct_move:
			_left_controller_direct_move.max_speed = _left_controller_original_max_speed * sprint_speed_multiplier
		if _right_controller_direct_move:
			_right_controller_direct_move.max_speed = _right_controller_original_max_speed * sprint_speed_multiplier
	
	else:
		# We are not sprinting
		emit_signal("sprinting_finished")
		_sprinting = false
		
		# Set both controllers' direct movement functions, if applicable, to their original speeds
		if _left_controller_direct_move:
			_left_controller_direct_move.max_speed = _left_controller_original_max_speed
		if _right_controller_direct_move:
			_right_controller_direct_move.max_speed = _right_controller_original_max_speed


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	
#	# Make sure player has at least one direct movement node
	var test_left_controller_nodes = _left_controller.get_children()
	for child in test_left_controller_nodes:
		if child is XRToolsMovementDirect:
			# At least one direct movement node found, so call base class
			return ._get_configuration_warning()
	
	# Get the right controller direct movement node, if any
	var test_right_controller_nodes = _right_controller.get_children()
	for child in test_right_controller_nodes:
		if child is XRToolsMovementDirect:
			# At least one direct movement node found, so call base class
			return ._get_configuration_warning()

	# Could not find any direct movement node if have not returned so far, so display error
	return "Unable to find XRToolsMovementDirect instance for player to support sprinting"
	
