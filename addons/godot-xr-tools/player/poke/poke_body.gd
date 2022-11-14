extends RigidBody

# distance at which we teleport our poke body
export var teleport_distance : float = 0.2

func _integrate_forces(state: PhysicsDirectBodyState):
	# get the position of our parent that we are following
	var following_transform = get_parent().global_transform

	# see how much we need to move
	var delta_movement = following_transform.origin - state.transform.origin
	var delta_length = delta_movement.length()

	if delta_length > teleport_distance:
		# teleport our poke body to its new location
		state.angular_velocity = Vector3()
		state.linear_velocity = Vector3()
		state.transform.origin = following_transform.origin
	else:
		# trigger physics to move our body in one step
		state.angular_velocity = Vector3()
		state.linear_velocity = delta_movement / state.step
		state.integrate_forces()
