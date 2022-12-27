class_name XRToolsMoveTo
extends Node


## XR Tools Move To Node
##
## This node moves a control node to the specified target node at a
## requested speed.


## Signal invoked when the move finishes
signal move_complete


# Spatial to control
var _control: Spatial

# Spatial representing the target
var _target: Spatial

# Starting transform
var _start: Transform

# Target offset
var _offset: Transform

# Move duration
var _duration: float

# Move time
var _time: float = 0.0


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsMoveTo" or .is_class(name)


## Initialize the XRToolsMoveTo
func _init():
	# Disable processing until needed
	set_process(false)


## Process the movement
func _process(delta: float) -> void:
	# Calculate the destination
	var destination := _target.global_transform * _offset

	# Update the move time
	_time += delta

	# Detect end of move
	if _time > _duration:
		# Disable processing
		set_process(false)

		# Move to the target
		_control.global_transform = destination

		# Report the move as complete
		emit_signal("move_complete")
		return

	# Interpolate to the target
	_control.global_transform = _start.interpolate_with(
		destination,
		_time / _duration)


## Start the move
func start(control: Spatial, target: Spatial, offset: Transform, speed: float) -> void:
	# Save the control and target
	_control = control
	_target = target
	_offset = offset

	# Save the starting transform
	_start = control.global_transform

	# Calculate the duration
	var destination := _target.global_transform * _offset
	var distance := (destination.origin - _start.origin).length()
	_duration = distance / speed

	# Start processing
	set_process(true)


## Stop the move
func stop() -> void:
	set_process(false)
