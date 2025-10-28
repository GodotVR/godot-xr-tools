class_name Grab
extends Grabber


## Grab Class
##
## This class encodes information about an active grab. Additionally it applies
## hand poses and collision exceptions as appropriate.


## Priority for grip poses
const GRIP_POSE_PRIORITY := 100

## Priority for grip targeting
const GRIP_TARGET_PRIORITY := 100


## Grab target
var what : XRToolsPickable

## Grab point information
var point : XRToolsGrabPoint

## Hand grab point information
var hand_point : XRToolsGrabPointHand

## Grab transform
var transform : Transform3D

## Position drive strength
var drive_position : float = 1.0

## Angle drive strength
var drive_angle : float = 1.0

## Aim drive strength
var drive_aim : float = 0.0

## Has target arrived at grab point
var _arrived : bool = false

## Collision exceptions we manage
var _collision_exceptions : Array[RID]


## Initialize the grab
func _init(
	p_grabber : Grabber,
	p_what : XRToolsPickable,
	p_point : XRToolsGrabPoint,
	p_precise : bool) -> void:

	# Copy the grabber information
	by = p_grabber.by
	pickup = p_grabber.pickup
	controller = p_grabber.controller
	hand = p_grabber.hand
	collision_hand = p_grabber.collision_hand

	# Set the point
	what = p_what
	point = p_point
	hand_point = p_point as XRToolsGrabPointHand

	# Calculate the grab transform
	if hand_point:
		# Get our adjusted grab point (palm position)
		transform = hand_point.get_palm_transform()
	elif point:
		transform = point.transform
	elif p_precise:
		transform = p_what.global_transform.affine_inverse() * by.global_transform
	else:
		transform = Transform3D.IDENTITY

	# Set the drive parameters
	if hand_point:
		drive_position = hand_point.drive_position
		drive_angle = hand_point.drive_angle
		drive_aim = hand_point.drive_aim

	# Apply collision exceptions
	if collision_hand:
		collision_hand.max_distance_reached.connect(_on_max_distance_reached)
		_add_collision_exceptions(what)


## Set the target as arrived at the grab-point
func set_arrived() -> void:
	# Ignore if already arrived
	if _arrived:
		return

	# Set arrived and apply any hand pose
	print_verbose("%s> arrived at %s" % [what.name, point])
	_arrived = true
	_set_hand_pose()

	# Report the grab
	print_verbose("%s> grabbed by %s", [what.name, by.name])
	what.grabbed.emit(what, by)


## Set the grab point
func set_grab_point(p_point : XRToolsGrabPoint) -> void:
	# Skip if no change
	if p_point == point:
		return

	# Remove any current pose override
	_clear_hand_pose()

	# Update the grab point
	point = p_point
	hand_point = point as XRToolsGrabPointHand

	# Update the transform
	if point:
		# Get our adjusted grab point (palm position)
		transform = p_point.get_palm_transform()

	# Apply the new hand grab-point settings
	if hand_point:
		drive_position = hand_point.drive_position
		drive_angle = hand_point.drive_angle
		drive_aim = hand_point.drive_aim

	# Apply any pose overrides
	if _arrived:
		_set_hand_pose()

	# Report switch
	print_verbose("%s> switched grab point to %s", [what.name, point.name])
	what.released.emit(what, by)
	what.grabbed.emit(what, by)


## Release the grip
func release() -> void:
	# Clear any hand pose
	_clear_hand_pose()

	# Remove collision exceptions with a small delay
	if is_instance_valid(collision_hand) and not _collision_exceptions.is_empty():
		# Use RIDs instead of the objects directly in case they get freed while
		# we are waiting for the object to fall away
		var copy : Array[RID] = _collision_exceptions.duplicate()
		_collision_exceptions.clear()

		# Delay removing our exceptions to give the object time to fall away
		collision_hand.get_tree().create_timer(0.5).timeout \
			.connect(_remove_collision_exceptions \
				.bind(copy) \
				.bind(collision_hand.get_rid()))

	# Report the release
	print_verbose("%s> released by %s", [what.name, by.name])
	what.released.emit(what, by)


# Hand has moved too far away from object, can no longer hold on to it.
func _on_max_distance_reached() -> void:
	pickup.drop_object()


# Set hand-pose overrides
func _set_hand_pose() -> void:
	# Skip if not hand
	if not is_instance_valid(hand) or not is_instance_valid(hand_point):
		return

	# Apply the hand-pose
	if hand_point.hand_pose:
		hand.add_pose_override(hand_point, GRIP_POSE_PRIORITY, hand_point.hand_pose)

	# Apply hand snapping
	if hand_point.snap_hand:
		hand.add_target_override(hand_point, GRIP_TARGET_PRIORITY)


# Clear any hand-pose overrides
func _clear_hand_pose() -> void:
	# Skip if not hand
	if not is_instance_valid(hand) or not is_instance_valid(hand_point):
		return

	# Remove hand-pose
	hand.remove_pose_override(hand_point)

	# Remove hand snapping
	hand.remove_target_override(hand_point)


# Add collision exceptions for the grabbed object and any of its children
func _add_collision_exceptions(from : Node):
	if not is_instance_valid(collision_hand):
		return

	if not is_instance_valid(from):
		return

	# If this is a physics body, add an exception
	if from is PhysicsBody3D:
		# Make sure we don't collide with what we're holding
		_collision_exceptions.push_back(from.get_rid())
		PhysicsServer3D.body_add_collision_exception(collision_hand.get_rid(), from.get_rid())
		PhysicsServer3D.body_add_collision_exception(from.get_rid(), collision_hand.get_rid())

	# Check all children
	for child in from.get_children():
		_add_collision_exceptions(child)


# Remove the exceptions in our passed array. We call this with a small delay
# to give an object a chance to drop away from the hand before it starts
# colliding.
# It is possible that another object is picked up in the meanwhile
# and we thus fill _collision_exceptions with new content.
# Hence using a copy of this list at the time of dropping the object.
#
# Note, this is static because our grab object gets destroyed before this code gets run.
static func _remove_collision_exceptions( \
	on_collision_hand : RID, \
	exceptions : Array[RID]):

	# This can be improved by checking if we're still colliding and only
	# removing those objects from our exception list that are not.
	# If any are left, we can restart a new timer.
	# This will also allow us to use a much smaller timer interval

	# For now we'll remove all.

	for body : RID in exceptions:
		PhysicsServer3D.body_remove_collision_exception(on_collision_hand, body)
		PhysicsServer3D.body_remove_collision_exception(body, on_collision_hand)
