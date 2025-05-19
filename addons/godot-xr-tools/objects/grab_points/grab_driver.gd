class_name XRToolsGrabDriver
extends RemoteTransform3D


## Grab state
enum GrabState {
	LERP,
	SNAP,
}


## Drive state
var state : GrabState = GrabState.SNAP

## Target pickable
var target : XRToolsPickable

## Primary grab information
var primary : Grab = null

## Secondary grab information
var secondary : Grab = null

## Lerp start position
var lerp_start : Transform3D

## Lerp total duration
var lerp_duration : float = 1.0

## Lerp time
var lerp_time : float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta : float) -> void:
	# Skip if no primary node
	if not is_instance_valid(primary):
		return

	# Set destination from primary grab
	var destination := primary.by.global_transform * primary.transform.affine_inverse()

	# If present, apply secondary-node contributions
	if is_instance_valid(secondary):
		# Calculate lerp coefficients based on drive strengths
		var position_lerp := _vote(primary.drive_position, secondary.drive_position)
		var angle_lerp := _vote(primary.drive_angle, secondary.drive_angle)

		# Calculate the transform from secondary grab
		var x1 := destination
		var x2 := secondary.by.global_transform * secondary.transform.affine_inverse()

		# Independently lerp the angle and position
		destination = Transform3D(
			x1.basis.slerp(x2.basis, angle_lerp),
			x1.origin.lerp(x2.origin, position_lerp))

		# Test if we need to apply aiming
		if secondary.drive_aim > 0.0:
			# Convert destination from global to primary-local
			destination = primary.by.global_transform.affine_inverse() * destination

			# Calculate the from and to vectors in primary-local space
			var secondary_from := destination * secondary.transform.origin
			var secondary_to := primary.by.to_local(secondary.by.global_position)

			# Build shortest arc
			secondary_from = secondary_from.normalized()
			secondary_to = secondary_to.normalized()
			var spherical := Quaternion(secondary_from, secondary_to)

			# Build aim-rotation
			var rotate := Basis.IDENTITY.slerp(Basis(spherical), secondary.drive_aim)
			destination = Transform3D(rotate, Vector3.ZERO) * destination

			# Convert destination from primary-local to global
			destination = primary.by.global_transform * destination

	# Handle update
	match state:
		GrabState.LERP:
			# Progress the lerp
			lerp_time += delta
			if lerp_time < lerp_duration:
				# Interpolate from lerp_start to destination
				destination = lerp_start.interpolate_with(
					destination,
					lerp_time / lerp_duration)
			else:
				# Lerp completed
				state = GrabState.SNAP
				_update_weight()
				if primary: primary.set_arrived()
				if secondary: secondary.set_arrived()

	if global_transform.is_equal_approx(destination):
		return

	# Apply the destination transform
	global_transform = destination
	force_update_transform()
	if is_instance_valid(target):
		target.force_update_transform()


## Set the secondary grab point
func add_grab(p_grab : Grab) -> void:
	# Set the secondary grab
	if p_grab.hand_point and p_grab.hand_point.mode == XRToolsGrabPointHand.Mode.PRIMARY:
		print_verbose("%s> new primary grab %s" % [target.name, p_grab.by.name])
		secondary = primary
		primary = p_grab
	else:
		print_verbose("%s> new secondary grab %s" % [target.name, p_grab.by.name])
		secondary = p_grab

	# If snapped then report arrived at the new grab
	if state == GrabState.SNAP:
		_update_weight()
		p_grab.set_arrived()


## Get the grab information for the grab node
func get_grab(by : Node3D) -> Grab:
	if primary and primary.by == by:
		return primary

	if secondary and secondary.by == by:
		return secondary

	return null


func remove_grab(p_grab : Grab) -> void:
	# Remove the appropriate grab
	if p_grab == primary:
		# Remove primary (secondary promoted)
		print_verbose("%s> %s (primary) released" % [target.name, p_grab.by.name])
		primary = secondary
		secondary = null
	elif p_grab == secondary:
		# Remove secondary
		print_verbose("%s> %s (secondary) released" % [target.name, p_grab.by.name])
		secondary = null

	if state == GrabState.SNAP:
		_update_weight()


# Discard the driver
func discard():
	remote_path = NodePath()
	queue_free()


# Create the driver to lerp the target from its current location to the
# primary grab-point.
static func create_lerp(
	p_target : Node3D,
	p_grab : Grab,
	p_lerp_speed : float) -> XRToolsGrabDriver:

	print_verbose("%s> lerping %s" % [p_target.name, p_grab.by.name])

	# Construct the driver lerping from the current position
	var driver := XRToolsGrabDriver.new()
	driver.name = p_target.name + "_driver"
	driver.top_level = true
	driver.process_physics_priority = -80
	driver.state = GrabState.LERP
	driver.target = p_target
	driver.primary = p_grab
	driver.global_transform = p_target.global_transform

	# Calculate the start and duration
	var end := p_grab.by.global_transform * p_grab.transform
	var delta := end.origin - p_target.global_position
	driver.lerp_start = p_target.global_transform
	driver.lerp_duration = delta.length() / p_lerp_speed

	# Add the driver as a neighbor of the target as RemoteTransform3D nodes
	# cannot be descendands of the targets they drive.
	p_target.get_parent().add_child(driver)
	driver.remote_path = driver.get_path_to(p_target)

	# Return the driver
	return driver


# Create the driver to instantly snap to the primary grab-point.
static func create_snap(
	p_target : Node3D,
	p_grab : Grab) -> XRToolsGrabDriver:

	print_verbose("%s> snapping to %s" % [p_target.name, p_grab.by.name])

	# Construct the driver snapped to the held position
	var driver := XRToolsGrabDriver.new()
	driver.name = p_target.name + "_driver"
	driver.top_level = true
	driver.process_physics_priority = -80
	driver.state = GrabState.SNAP
	driver.target = p_target
	driver.primary = p_grab
	driver.global_transform = p_grab.by.global_transform * p_grab.transform.affine_inverse()

	# Snapped to grab-point so report arrived
	p_grab.set_arrived()

	# Add the driver as a neighbor of the target as RemoteTransform3D nodes
	# cannot be descendands of the targets they drive.
	p_target.get_parent().add_child(driver)
	driver.remote_path = driver.get_path_to(p_target)

	driver._update_weight()

	# Return the driver
	return driver


# Calculate the lerp voting from a to b
static func _vote(a : float, b : float) -> float:
	if a == 0.0 and b == 0.0:
		return 0.0

	return b / (a + b)


# Update the weight on collision hands
func _update_weight():
	if primary:
		var weight : float = target.mass
		if secondary:
			# Each hand carries half the weight
			weight = weight / 2.0
			if secondary.collision_hand:
				secondary.collision_hand.set_held_weight(weight)

		if primary.collision_hand:
			primary.collision_hand.set_held_weight(weight)
