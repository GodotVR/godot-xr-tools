class_name VelocityAverager


##
## Velocity Averager class
##
## @desc:
##     This class assists in calculating the velocity (both linear and angular)
##     of an object. It accepts the following types of input:
##      - Periodic distances
##      - Periodic transforms (for the origin position)
##
##     It provides the average velocity calculated from the total distance 
##     divided by the total time.
## 


# Count of averages to perform
var _count: int

# Array of time deltas (in float seconds) 
var _time_deltas := Array()

# Array of linear distances (Vector3 Castesian Distances)
var _linear_distances := Array()

# Array of angular distances (Vector3 Euler Distances)
var _angular_distances := Array()

# Last transform
var _last_transform := Transform()

# Has last transform flag
var _has_last_transform := false


## Initialize the VelocityAverager with an averaging count
func _init(var count: int):
	_count = count

## Clear the averages
func clear():
	_time_deltas.clear()
	_linear_distances.clear()
	_angular_distances.clear()
	_has_last_transform = false

## Add linear and angular distances to the averager
func add_distance(var delta: float, var linear_distance: Vector3, var angular_distance: Vector3):
	# Sanity check
	assert(delta > 0, "Velocity averager requires positive time-deltas")
	
	# Add data averaging arrays
	_time_deltas.push_back(delta)
	_linear_distances.push_back(linear_distance)
	_angular_distances.push_back(angular_distance)

	# Keep the number of samples down to the requested count
	if _time_deltas.size() > _count:
		_time_deltas.pop_front()
		_linear_distances.pop_front()
		_angular_distances.pop_front()

## Add a transform to the averager
func add_transform(var delta: float, var transform: Transform):
	# Handle saving the first transform
	if !_has_last_transform:
		_last_transform = transform
		_has_last_transform = true
		return

	# Calculate the linear cartesian distance
	var linear_distance := transform.origin - _last_transform.origin
	
	# Calculate the euler angular distance
	var angular_distance := (transform.basis * _last_transform.basis.inverse()).get_euler()
	
	# Update the last transform
	_last_transform = transform
	
	# Add distances
	add_distance(delta, linear_distance, angular_distance)

## Calculate the average linear velocity
func linear_velocity() -> Vector3:
	# Skip if no averages
	if _time_deltas.size() == 0:
		return Vector3.ZERO

	# Calculate the total time in the average window
	var total_time := 0.0
	for dt in _time_deltas:
		total_time += dt

	# Sum the cartesian distances in the average window
	var total_linear := Vector3.ZERO
	for dd in _linear_distances:
		total_linear += dd

	# Return the average cartesian-velocity
	return total_linear / total_time

## Calculate the average angular velocity as a Vector3 euler-velocity
func angular_velocity() -> Vector3:
	# Skip if no averages
	if _time_deltas.size() == 0:
		return Vector3.ZERO

	# Calculate the total time in the average window
	var total_time := 0.0
	for dt in _time_deltas:
		total_time += dt

	# At first glance the following operations may look incorrect as they appear
	# to involve scaling of euler angles which isn't a valid operation.
	#
	# They are actually correct due to the value being a euler-velocity rather
	# than a euler-angle. The difference is that physics engines process euler 
	# velocities by converting them to axis-angle form by:
	# - Angle-velocity: euler-velocity vector magnitude
	# - Axis: euler-velocity normalized and axis evaluated on 1-radian rotation
	#
	# The result of this interpretation is that scaling the euler-velocity
	# by arbitrary amounts only results in the angle-velocity changing without
	# impacting the axis of rotation.

	# Sum the euler-velocities in the average window
	var total_angular := Vector3.ZERO
	for dd in _angular_distances:
		total_angular += dd

	# Calculate the average euler-velocity
	return total_angular / total_time
