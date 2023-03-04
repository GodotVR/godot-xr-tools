class_name XRToolsVelocityAveragerLinear


## XR Tools Linear Velocity Averager class
##
## This class assists in calculating the average linear velocity of an
## object. It accepts the following types of input:
##  - Periodic distances
##  - Periodic velocities
##  - Periodic transforms (for the origin position)
##
## It provides the average velocity calculated from the total distance
## divided by the total time.


# Count of averages to perform
var _count: int

# Array of time deltas (in float seconds)
var _time_deltas := Array()

# Array of linear distances (in Vector3)
var _linear_distances := Array()

# Last transform
var _last_transform := Transform3D()

# Has last transform flag
var _has_last_transform := false


## Initialize the VelocityAverager with an averaging count
func _init(count: int):
	_count = count

## Clear the averages
func clear():
	_time_deltas.clear()
	_linear_distances.clear()
	_has_last_transform = false

## Add a linear distance to the averager
func add_distance(delta: float, linear_distance: Vector3):
	# Add data averaging arrays
	_time_deltas.push_back(delta)
	_linear_distances.push_back(linear_distance)

	# Keep the number of samples down to the requested count
	if _time_deltas.size() > _count:
		_time_deltas.pop_front()
		_linear_distances.pop_front()

## Add a linear velocity to the averager
func add_velocity(delta: float, linear_velocity: Vector3):
	add_distance(delta, linear_velocity * delta)

## Add a transform to the averager
func add_transform(delta: float, transform: Transform3D):
	# Handle saving the first transform
	if !_has_last_transform:
		_last_transform = transform
		_has_last_transform = true
		return

	# Calculate the linear distances
	var linear_distance := transform.origin - _last_transform.origin

	# Update the last transform
	_last_transform = transform

	# Add distance
	add_distance(delta, linear_distance)

## Calculate the average linear velocity
func velocity() -> Vector3:
	# Calculate the total time
	var total_time := 0.0
	for dt in _time_deltas:
		total_time += dt

	# Safety check to prevent division by zero
	if total_time <= 0.0:
		return Vector3.ZERO

	# Calculate the total distance
	var total_linear := Vector3.ZERO
	for dd in _linear_distances:
		total_linear += dd

	# Return the average
	return total_linear / total_time
