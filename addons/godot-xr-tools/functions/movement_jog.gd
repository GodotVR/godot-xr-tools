@tool
class_name XRToolsMovementJog
extends XRToolsMovementProvider


## XR Tools Movement Provider for Jog Movement
##
## This script provides jog-in-place movement for the player. This script
## works with the [XRToolsPlayerBody] attached to the players [XROrigin3D].
##
## The implementation uses filtering of the controller Y velocities to measure
## the approximate frequency of jog arm-swings; and uses that to
## switch between stopped, slow, and fast movement speeds.


## Speed mode enumeration
enum SpeedMode {
	STOPPED,	## Not jogging
	SLOW,		## Jogging slowly
	FAST		## Jogging fast
}


## Jog arm-swing frequency in Hz to trigger slow movement
const JOG_SLOW_FREQ := 3.5

## Jog arm-swing frequency in Hz to trigger fast movement
const JOG_FAST_FREQ := 5.5


## Movement provider order
@export var order : int = 10

## Slow jogging speed in meters-per-second
@export var slow_speed : float = 1.0

## Fast jogging speed in meters-per-second
@export var fast_speed : float = 3.0


# Jog arm-swing "stroke" detector "confidence-hat" signal
var _conf_hat := 0.0

# Current jog arm-swing "stroke" duration
var _current_stroke := 0.0

# Last jog arm-swing "stroke" total duration
var _last_stroke := 0.0

# Current jog-speed mode
var _speed_mode := SpeedMode.STOPPED


# Left controller
@onready var _left_controller := XRHelpers.get_left_controller(self)

# Right controller
@onready var _right_controller := XRHelpers.get_right_controller(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementJog" or super(name)


# Perform jump movement
func physics_movement(delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the either controller is inactive
	if !_left_controller.get_is_active() or !_right_controller.get_is_active():
		_speed_mode = SpeedMode.STOPPED
		return

	# Get the arm-swing stroke frequency in Hz
	var freq := _get_stroke_frequency(delta)

	# Transition between stopped/slow/fast speed-modes based on thresholds.
	# This thresholding has some hysteresis to make speed changes smoother.
	if freq == 0:
		_speed_mode = SpeedMode.STOPPED
	elif freq < JOG_SLOW_FREQ:
		_speed_mode = min(_speed_mode, SpeedMode.SLOW)
	elif freq < JOG_FAST_FREQ:
		_speed_mode = max(_speed_mode, SpeedMode.SLOW)
	else:
		_speed_mode = SpeedMode.FAST

	# Pick the speed in meters-per-second based on the current speed-mode.
	var speed := 0.0
	if _speed_mode == SpeedMode.SLOW:
		speed = slow_speed
	elif _speed_mode == SpeedMode.FAST:
		speed = fast_speed

	# Contribute to the player body speed - with clamping to the maximum speed
	player_body.ground_control_velocity.y += speed
	var length := player_body.ground_control_velocity.length()
	if length > fast_speed:
		player_body.ground_control_velocity *= fast_speed / length


# Get the frequency of the last arm-swing "stroke" in Hz.
func _get_stroke_frequency(delta : float) -> float:
	# Get the controller velocities
	var vl := _left_controller.get_pose().linear_velocity.y
	var vr := _right_controller.get_pose().linear_velocity.y

	# Calculate the arm-swing "stroke" confidence. This is done by multiplying
	# the left and right controller vertical velocities. As these velocities
	# are highly anti-correlated while "jogging" the result is a confidence
	# signal with a high "peak" on every jog "stroke".
	var conf := vl * -vr

	# Test for the confidence valley between strokes. This is used to signal
	# when to measure the duration between strokes.
	var valley := conf < _conf_hat

	# Update confidence-hat. The confidence-hat signal has a fast-rise and
	# slow-decay. Rising with each jog arm-swing "stroke" and then taking time
	# to decay. The magnitude of the "confidence-hat" can be used as a good
	# indicator of when the user is jogging; and the difference between the
	# "confidence" and "confidence-hat" signals can be used to identify the
	# duration of a jog arm-swing "stroke".
	if valley:
		# Gently decay when in the confidence valley.
		_conf_hat = lerpf(_conf_hat, 0.0, delta * 2)
	else:
		# Quickly ramp confidence-hat to confidence
		_conf_hat = lerpf(_conf_hat, conf, delta * 20)

	# If the "confidence-hat" signal is too low then the user is not jogging.
	# The stroke date-data is cleared and a stroke frequency of 0Hz is returned.
	if _conf_hat < 0.5:
		_current_stroke = 0.0
		_last_stroke = 0.0
		return 0.0

	# Track the jog arm-swing "stroke" duration.
	if valley:
		# In the valley between jog arm-swing "strokes"
		_current_stroke += delta
	elif _current_stroke > 0.1:
		# Save the measured jog arm-swing "stroke" duration.
		_last_stroke = _current_stroke
		_current_stroke = 0.0

	# If no previous jog arm-swing "stroke" duration to report, so return 0Hz.
	if _last_stroke < 0.1:
		return 0.0

	# If the current jog arm-swing "stroke" is taking longer (slower) than 2Hz
	# then truncate to 0Hz.
	if _current_stroke > 0.75:
		return 0.0

	# Return the last jog arm-swing "stroke" in Hz.
	return 1.0 / _last_stroke
