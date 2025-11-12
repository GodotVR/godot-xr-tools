@tool
class_name XRToolsForceBody
extends AnimatableBody3D


## XRTools Force Body script
##
## This script enhances AnimatableBody3D with move_and_slide and the ability
## to push bodies by emparting forces on them.


## Force Body Collision
class ForceBodyCollision:
	## Collider object
	var collider : Node3D

	## Collision point
	var position : Vector3

	## Collision normal
	var normal : Vector3


## Enables or disables pushing bodies
@export var push_bodies : bool = true

## Control the stiffness of the body
@export var stiffness : float = 10.0

## Control the maximum push force
@export var maximum_force : float = 1.0

## Maximum slides
@export var max_slides : int = 4


## Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsForceBody"


## This function moves and slides along the [param move] vector. It returns
## information about the last collision, or null if no collision
func move_and_slide(move : Vector3) -> ForceBodyCollision:
	# Make sure this is off or weird shit happens...
	sync_to_physics = false

	# Loop performing the movement steps
	var step_move := move
	var ret : ForceBodyCollision = null
	for step in max_slides:
		# Take the next step
		var collision := move_and_collide(step_move)

		# If we didn't collide with anything then we have finished the entire
		# move_and_slide operation
		if not collision:
			break

		# Save relevant collision information
		var collider := collision.get_collider()
		var postion := collision.get_position()
		var normal := collision.get_normal()

		# Save the collision information
		if not ret:
			ret = ForceBodyCollision.new()

		ret.collider = collider
		ret.position = postion
		ret.normal = normal

		# Calculate the next move
		var next_move := collision.get_remainder().slide(normal)

		# Handle pushing bodies
		if push_bodies:
			var body := collider as RigidBody3D
			if body:
				# Calculate the momentum lost by the collision
				var lost_momentum := step_move - next_move

				# TODO: We should consider the velocity of the body such that
				# we never push it away faster than our own velocity.

				# Apply the lost momentum as an impulse to the body we hit
				body.apply_impulse(
					(lost_momentum * stiffness).limit_length(maximum_force),
					position - body.global_position)

		# Update the remaining movement
		step_move = next_move

		# Prevent bouncing back along movement path
		if next_move.dot(move) <= 0:
			break

	# Return the last collision data
	return ret


## Attempts to rotate our object until it collides
func rotate_and_collide( \
	target_global_basis : Basis, \
	step_angle : float = deg_to_rad(5.0) \
	) -> ForceBodyCollision:
	# Make sure this is off or weird shit happens...
	sync_to_physics = false

	var ret : ForceBodyCollision = null

	var space = PhysicsServer3D.body_get_space(get_rid())
	var direct_state = PhysicsServer3D.space_get_direct_state(space)

	# We don't seem to have a rotational movement query for collisions,
	# so best we can do is to rotate in steps and test
	var from_quat : Quaternion = Quaternion(global_basis)
	var to_quat : Quaternion = Quaternion(target_global_basis)
	var angle : float = from_quat.angle_to(to_quat)
	var steps : float = ceil(angle / step_angle)

	# Convert collision exceptions to a RID array
	var exception_rids : Array[RID]
	for collision_exception in get_collision_exceptions():
		# It is our responsibility to remove exceptions before freeing the object, but sometimes
		# that is hard.
		if is_instance_valid(collision_exception):
			exception_rids.push_back(collision_exception.get_rid())
		else:
			push_warning("freed object still exists in a collision exception")

	# Prevent collisions with ourselves
	exception_rids.push_back(get_rid())

	# Find our shape ids
	var shape_rids : Array[RID]
	for node in get_children(true):
		if node is CollisionShape3D:
			var col_shape : CollisionShape3D = node
			if not col_shape.disabled:
				shape_rids.push_back(col_shape.shape.get_rid())

	# Our physics query
	var query : PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = collision_mask
	query.exclude = exception_rids

	# Check our collisions
	var step : float = 0.0
	var new_quat : Quaternion = from_quat
	var t = global_transform
	while step < steps and not ret:
		step += 1.0

		var test_quat : Quaternion = from_quat.slerp(to_quat, step / steps)
		t.basis = Basis(test_quat)
		query.transform = t

		for rid in shape_rids:
			query.shape_rid = rid
			var collision = direct_state.get_rest_info(query)
			if not collision.is_empty():
				ret = ForceBodyCollision.new()
				ret.collider = instance_from_id(collision["collider_id"])
				ret.position = collision["point"]
				ret.normal = collision["normal"]

				# TODO May need to see about applying a rotational force
				# if pushbodies is true

				break

		if not ret:
			# No collision, we can rotate this far!
			new_quat = test_quat

	# Update our rotation to our last successful rotation
	global_basis = Basis(new_quat)

	# Return the last collision data
	return ret


func _ready():
	process_physics_priority = -90
