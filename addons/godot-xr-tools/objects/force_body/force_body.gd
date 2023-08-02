@tool
class_name XRToolsForceBody
extends StaticBody3D


## XRTools Force Body script
##
## This script enhances StaticBody3D with move_and_slide and the ability
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
func is_xr_class(name : String) -> bool:
	return name == "XRToolsForceBody"


## This function moves and slides along the [param move] vector. It returns
## information about the last collision, or null if no collision
func move_and_slide(move : Vector3) -> ForceBodyCollision:
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
