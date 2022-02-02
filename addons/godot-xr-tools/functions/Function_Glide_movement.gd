tool
class_name Function_Glide
extends MovementProvider

##
## Movement Provider for Gliding
##
## @desc:
##     This script works with the Function_Glide_movement asset to provide glide
##     mechanics for the player. This script works with the PlayerBody attached
##     to the players ARVROrigin.
##
##     The player enables flying by moving the controllers apart further than
##     'glide_detect_distance'.
##
##     When gliding, the players fall speed will slew to 'glide_fall_speed' and
##     the velocity will slew to 'glide_forward_speed' in the direction the
##     player is facing.
##
##     Gliding is an exclusive motion operation, and so gliding should be ordered
##     after any Direct movement providers responsible for turning.
##

## Signal invoked when the player starts gliding
signal player_glide_start

## Signal invoked when the player ends gliding
signal player_glide_end

## Movement provider order
export var order := 30

## Controller separation distance to register as glide
export var glide_detect_distance := 1.0

## Minimum falling speed to be considered gliding
export var glide_min_fall_speed = -1.5

## Glide falling speed
export var glide_fall_speed := -2.0

## Glide forward speed
export var glide_forward_speed := 12.0

## Slew rate to transition to gliding
export var horizontal_slew_rate := 1.0

## Slew rate to transition to gliding
export var vertical_slew_rate := 2.0

## Left ARVR Controller
export (NodePath) var left_controller = null

## Right ARVR Controller
export (NodePath) var right_controller = null

# Node references
var _left_controller_node: ARVRController = null
var _right_controller_node: ARVRController = null

# Is the player gliding
var is_gliding := false

# Horizontal vector (multiply by this to get only the horizontal components
const horizontal := Vector3(1.0, 0.0, 1.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the controllers
	_left_controller_node = get_node(left_controller) if left_controller else get_node("../LeftHandController")
	_right_controller_node = get_node(right_controller) if right_controller else get_node("../RightHandController")

func physics_movement(delta: float, player_body: PlayerBody):
	# Skip if either controller is off
	if !_left_controller_node.get_is_active() or !_right_controller_node.get_is_active():
		return

	# If on the ground, or not falling, then not gliding
	if player_body.on_ground || player_body.velocity.y >= glide_min_fall_speed:
		_set_is_gliding(false)
		return

	# Get the controller left ands right global horizontal positions
	var left_position := _left_controller_node.global_transform.origin * horizontal
	var right_position := _right_controller_node.global_transform.origin * horizontal
	var left_to_right := right_position - left_position

	# If the hands are too close then not gliding
	if left_to_right.length() < glide_detect_distance:
		_set_is_gliding(false)
		return

	# Lerp the vertical velocity to glide_fall_speed
	var vertical_velocity := player_body.velocity.y
	vertical_velocity = lerp(vertical_velocity, glide_fall_speed, vertical_slew_rate * delta)

	# Lerp the horizontal velocity towards forward_speed
	var horizontal_velocity := player_body.velocity * horizontal
	var dir_forward := left_to_right.rotated(Vector3.UP, PI/2).normalized()
	var forward_velocity := dir_forward * glide_forward_speed
	horizontal_velocity = lerp(horizontal_velocity, forward_velocity, horizontal_slew_rate * delta)

	# Perform the glide
	var glide_velocity := horizontal_velocity + vertical_velocity * Vector3.UP
	player_body.velocity = player_body.move_and_slide(glide_velocity)

	# Report exclusive motion performed (to bypass gravity)
	return true

# Set the is_gliding flag and fire any signals
func _set_is_gliding(gliding: bool):
	# Skip if no change
	if gliding == is_gliding:
		return

	# Update the is_gliding flag
	is_gliding = gliding;
	
	# Report transition
	if is_gliding:
		emit_signal("player_glide_start")
	else:
		emit_signal("player_glide_end")

# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Verify the left controller
	var test_left_controller_node = get_node_or_null(left_controller) if left_controller else get_node_or_null("../LeftHandController")
	if !test_left_controller_node or !test_left_controller_node is ARVRController:
		return "Unable to find left ARVR Controller node"

	# Verify the right controller
	var test_right_controller_node = get_node_or_null(right_controller) if right_controller else get_node_or_null("../RightHandController")
	if !test_right_controller_node or !test_right_controller_node is ARVRController:
		return "Unable to find right ARVR Controller node"

	# Check glide parameters
	if glide_min_fall_speed > 0:
		return "Glide minimum fall speed must be zero or less"
	if glide_fall_speed > 0:
		return "Glide fall speed must be zero or less"
	if glide_min_fall_speed < glide_fall_speed:
		return "Glide fall speed must be faster than minimum fall speed"

	# Call base class
	return ._get_configuration_warning()
