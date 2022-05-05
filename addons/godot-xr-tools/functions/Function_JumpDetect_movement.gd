tool
class_name Function_JumpDetect
extends MovementProvider


##
## Movement Provider for Player Jump Detection
##
## @desc:
##     This script can detect jumping based on either the players body jumping,
##     or by the player swinging their arms up.
##
##     The player body jumping is detected by putting the cameras instantaneous
##     Y velocity (in the tracking space) into a sliding-window averager. If the
##     average Y velocity exceeds a threshold parameter then the player has
##     jumped.
##
##     The player arms jumping is detected by putting both controllers instantaneous
##     Y velocity (in the tracking space) into a sliding-window averager. If both
##     average Y velocities exceed a threshold parameter then the player has
##     jumped. 
##


## Movement provider order
export var order := 20

## Enable detecting of jump via body (through the camera)
export var body_jump_enable := true

## Only jump as high as the player (no ground physics)
export var body_jump_player_only := false

## Body jump detection threshold (M/S^2)
export var body_jump_threshold := 2.5

## Enable detectionm of jump via arms (through the controllers)
export var arms_jump_enable := false

## Arms jump detection threshold (M/S^2)
export var arms_jump_threshold := 5.0


# Sliding Average class
class SlidingAverage:
	# Sliding window size
	var _size: int

	# Sum of items in the window
	var _sum := 0.0

	# Position
	var _pos := 0

	# Data window
	var _data := Array()

	# Constructor
	func _init(var size: int):
		# Set the size and fill the array
		_size = size
		for i in size:
			_data.push_back(0.0)

	# Update the average
	func update(var entry: float) -> float:
		# Add the new entry and subtract the old
		_sum += entry
		_sum -= _data[_pos]

		# Store the new entry in the array and circularly advance the index
		_data[_pos] = entry;
		_pos = (_pos + 1) % _size

		# Return the average
		return _sum / _size


# Node Positions
var _camera_position := 0.0
var _controller_left_position := 0.0
var _controller_right_position := 0.0

# Node Velocities
var _camera_velocity := SlidingAverage.new(5)
var _controller_left_velocity := SlidingAverage.new(5)
var _controller_right_velocity := SlidingAverage.new(5)

# Node references
onready var _origin_node := ARVRHelpers.get_arvr_origin(self)
onready var _camera_node := ARVRHelpers.get_arvr_camera(self)
onready var _controller_left_node := ARVRHelpers.get_left_controller(self)
onready var _controller_right_node := ARVRHelpers.get_right_controller(self)


# Perform jump detection
func physics_movement(delta: float, player_body: PlayerBody, _disabled: bool):
	# Handle detecting body jump
	if body_jump_enable:
		_detect_body_jump(delta, player_body)
	
	# Handle detecting arms jump
	if arms_jump_enable:
		_detect_arms_jump(delta, player_body)


# Detect the player jumping with their body (using the headset camera)
func _detect_body_jump(delta: float, player_body: PlayerBody) -> void:
	# Get the camera instantaneous velocity
	var new_camera_pos := _camera_node.transform.origin.y
	var camera_vel := (new_camera_pos - _camera_position) / delta
	_camera_position = new_camera_pos

	# Ignore zero moves (either not tracking, or no update since last physics)
	if abs(camera_vel) < 0.001:
		return;

	# Clamp the camera instantaneous velocity to +/- 2x the jump threshold
	camera_vel = clamp(camera_vel, -2.0 * body_jump_threshold, 2.0 * body_jump_threshold)

	# Get the averaged velocity
	camera_vel = _camera_velocity.update(camera_vel)

	# Detect a jump
	if camera_vel >= body_jump_threshold:
		player_body.request_jump(body_jump_player_only)


# Detect the player jumping with their arms (using the controllers)
func _detect_arms_jump(delta: float, player_body: PlayerBody) -> void:
	# Skip if either of the controllers is disabled
	if !_controller_left_node.get_is_active() or !_controller_right_node.get_is_active():
		return

	# Get the controllers instantaneous velocity
	var new_controller_left_pos := _controller_left_node.transform.origin.y
	var new_controller_right_pos := _controller_right_node.transform.origin.y
	var controller_left_vel := (new_controller_left_pos - _controller_left_position) / delta
	var controller_right_vel := (new_controller_right_pos - _controller_right_position) / delta
	_controller_left_position = new_controller_left_pos
	_controller_right_position = new_controller_right_pos

	# Ignore zero moves (either not tracking, or no update since last physics)
	if abs(controller_left_vel) <= 0.001 and abs(controller_right_vel) <= 0.001:
		return

	# Clamp the controller instantaneous velocity to +/- 2x the jump threshold
	controller_left_vel = clamp(controller_left_vel, -2.0 * arms_jump_threshold, 2.0 * arms_jump_threshold)
	controller_right_vel = clamp(controller_right_vel, -2.0 * arms_jump_threshold, 2.0 * arms_jump_threshold)

	# Get the averaged velocity
	controller_left_vel = _controller_left_velocity.update(controller_left_vel)
	controller_right_vel = _controller_right_velocity.update(controller_right_vel)

	# Detect a jump
	if controller_left_vel >= arms_jump_threshold and controller_right_vel >= arms_jump_threshold:
		player_body.request_jump()
