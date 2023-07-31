extends StaticBody3D


## Signal called when we start to contact an object
signal body_contact_start(node)

## Signal called when we end contact with an object
signal body_contact_end(node)


## Distance at which we teleport our poke body
@export var teleport_distance : float = 0.1

## Enable or disable pushing rigid bodies
@export var push_bodies : bool = true

## Stiffness of the finger
@export var stiffness : float = 10.0

## Maximum finger force
@export var maximum_force : float = 1.0


# Node currently in contact with
var _contact : Node3D = null

# Target XRToolsPoke
@onready var _target : XRToolsPoke = get_parent()


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPokeBody"


# Try moving to the parent Poke node
func _physics_process(_delta):
	# Get the current position and contact
	var old_position := global_position
	var old_contact := _contact

	# Calculate the movement to perform
	var target_position := _target.global_position
	var to_target := target_position - old_position
	var effort := to_target.length()

	# Decide whether to teleport or slide
	if effort > teleport_distance:
		# Perform Teleport
		global_position = target_position
	else:
		# Perform Slide (up to 4 times)
		_contact = null
		var force_direction := to_target.normalized()
		var next_direction := force_direction
		for n in 4:
			# Calculate how efficiently we can move/slide
			var efficiency := next_direction.dot(force_direction)
			if efficiency <= 0.0 or effort <= 0.0:
				break

			# Perform the move
			var step_physical := effort * efficiency
			var collision := move_and_collide(next_direction * step_physical)

			# If no collision then we have moved the rest of the distance
			if not collision:
				break

			# Calculate how much of the move remains [0..1]
			var remains := collision.get_remainder().length() / step_physical
			remains = clamp(remains, 0.0, 1.0)

			# Update the remaining effort
			effort *= remains

			# Calculate the next slide direction
			next_direction = force_direction.slide(collision.get_normal()).normalized()

			# Save the contact
			_contact = collision.get_collider()

			# Optionally support pushing rigid bodies
			if push_bodies:
				var contact_rigid := _contact as RigidBody3D
				if contact_rigid:
					# Calculate the finger force
					var force := target_position - global_position
					force *= stiffness
					force = force.limit_length(maximum_force)

					# Apply as an impulse
					contact_rigid.apply_impulse(
						force,
						collision.get_position() - contact_rigid.global_position)

	# Report when we stop being in contact with the current object
	if old_contact and old_contact != _contact:
		body_contact_end.emit(old_contact)

	# Report when we start touching a new object
	if _contact and _contact != old_contact:
		body_contact_start.emit(_contact)
