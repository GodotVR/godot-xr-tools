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
	if p_point:
		transform = p_point.transform
	elif p_precise:
		transform = p_what.global_transform.inverse() * by.global_transform
	else:
		transform = Transform3D.IDENTITY

	# Set the drive parameters
	if hand_point:
		drive_position = hand_point.drive_position
		drive_angle = hand_point.drive_angle
		drive_aim = hand_point.drive_aim

	# Apply collision exceptions
	if collision_hand:
		what.add_collision_exception_with(collision_hand)
		collision_hand.add_collision_exception_with(what)


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
		transform = point.transform

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

	# Remove collision exceptions
	if is_instance_valid(collision_hand):
		what.remove_collision_exception_with(collision_hand)
		collision_hand.remove_collision_exception_with(what)

	# Report the release
	print_verbose("%s> released by %s", [what.name, by.name])
	what.released.emit(what, by)


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
