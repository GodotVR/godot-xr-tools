@tool
class_name XRToolsPickable
extends RigidBody3D


## XR Tools Pickable Object
##
## This script allows a [RigidBody3D] to be picked up by an
## [XRToolsFunctionPickup] attached to a players controller.
##
## Additionally pickable objects may support being snapped into
## [XRToolsSnapZone] areas.
##
## Grab-points can be defined by adding different types of [XRToolsGrabPoint]
## child nodes controlling hand and snap-zone grab locations.


# Signal emitted when the user picks up this object
signal picked_up(pickable)

# Signal emitted when the user drops this object
signal dropped(pickable)

# Signal emitted when the user presses the action button while holding this object
signal action_pressed(pickable)

# Signal emitted when the highlight state changes
signal highlight_updated(pickable, enable)


## Method used to hold object
enum HoldMethod {
	REMOTE_TRANSFORM,	## Object is held via a remote transform
	REPARENT,			## Object is held by reparenting
}

## Method used to grab object at range
enum RangedMethod {
	NONE,				## Ranged grab is not supported
	SNAP,				## Object snaps to holder
	LERP,				## Object lerps to holder
}

## Current pickable object state
enum PickableState {
	IDLE,				## Object not held
	GRABBING_RANGED,	## Object being grabbed at range
	HELD,				## Object held
}

enum ReleaseMode {
	ORIGINAL = -1,		## Preserve original mode when picked up
	UNFROZEN = 0,		## Release and unfreeze
	FROZEN = 1,			## Release and freeze
}


# Default layer for held objects is 17:held-object
const DEFAULT_LAYER := 0b0000_0000_0000_0001_0000_0000_0000_0000

## Priority for grip poses
const GRIP_POSE_PRIORITY = 100


## If true, the pickable supports being picked up
@export var enabled : bool = true

## If true, the grip control must be held to keep the object picked up
@export var press_to_hold : bool = true

## Layer for this object while picked up
@export_flags_3d_physics var picked_up_layer = DEFAULT_LAYER

## Method used to hold an object
@export var hold_method : HoldMethod = HoldMethod.REMOTE_TRANSFORM

## Release mode to use when releasing the object
@export var release_mode : ReleaseMode = ReleaseMode.ORIGINAL

## Method used to perform a ranged grab
@export var ranged_grab_method : RangedMethod = RangedMethod.SNAP: set = _set_ranged_grab_method

## Speed for ranged grab
@export var ranged_grab_speed : float = 20.0

## Refuse pick-by when in the specified group
@export var picked_by_exclude : String = ""

## Require pick-by to be in the specified group
@export var picked_by_require : String = ""


## If true, the object can be picked up at range
var can_ranged_grab: bool = true

## Frozen state to restore to when dropped
var restore_freeze : bool = false

## Entity holding this item
var picked_up_by: Node3D = null

## Controller holding this item (may be null if held by snap-zone)
var by_controller : XRController3D = null

## What node "holds" the object
var hold_node : Node3D = null

## Hand holding this item (may be null if held by snap-zone)
var by_hand : XRToolsHand = null

## Collision hand holding this item (may be null)
var by_collision_hand : XRToolsCollisionHand = null

# Count of 'is_closest' grabbers
var _closest_count: int = 0

# Current state
var _state = PickableState.IDLE

# Remote transform
var _remote_transform: RemoteTransform3D = null

# Move-to node for performing remote grab
var _move_to: XRToolsMoveTo = null

# Array of grab points
var _grab_points : Array = []

# Currently active grab-point
var _active_grab_point : XRToolsGrabPoint

# Dictionary of nodes requesting highlight
var _highlight_requests : Dictionary = {}

# Is this node highlighted
var _highlighted : bool = false


# Remember some state so we can return to it when the user drops the object
@onready var original_parent = get_parent()
@onready var original_collision_mask : int = collision_mask
@onready var original_collision_layer : int = collision_layer


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPickable"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get all grab points
	for child in get_children():
		var grab_point := child as XRToolsGrabPoint
		if grab_point:
			_grab_points.push_back(grab_point)


# Test if this object can be picked up
func can_pick_up(_by: Node3D) -> bool:
	return enabled and _state == PickableState.IDLE


# Test if this object is picked up
func is_picked_up():
	return _state == PickableState.HELD


# action is called when user presses the action button while holding this object
func action():
	# let interested parties know
	emit_signal("action_pressed", self)


## This method requests highlighting of the [XRToolsPickable].
## If [param from] is null then all highlighting requests are cleared,
## otherwise the highlight request is associated with the specified node.
func request_highlight(from : Node, on : bool = true) -> void:
	# Save if we are highlighted
	var old_highlighted := _highlighted

	# Update the highlight requests dictionary
	if not from:
		_highlight_requests.clear()
	elif on:
		_highlight_requests[from] = from
	else:
		_highlight_requests.erase(from)

	# Update the highlighted state
	_highlighted = _highlight_requests.size() > 0

	# Report any changes
	if _highlighted != old_highlighted:
		emit_signal("highlight_updated", self, _highlighted)


func drop_and_free():
	if picked_up_by:
		picked_up_by.drop_object()

	queue_free()


# Called when this object is picked up
func pick_up(by: Node3D, with_controller: XRController3D) -> void:
	# Skip if disabled or already picked up
	if not enabled or _state != PickableState.IDLE:
		return

	if picked_up_by:
		let_go(Vector3.ZERO, Vector3.ZERO)

	# remember who picked us up
	picked_up_by = by
	by_controller = with_controller
	hold_node = with_controller if with_controller else by
	by_hand = XRToolsHand.find_instance(by_controller)
	by_collision_hand = XRToolsCollisionHand.find_instance(by_controller)
	_active_grab_point = _get_grab_point(by)

	# If we have been picked up by a hand then apply the hand-pose-override
	# from the grab-point.
	if by_hand and _active_grab_point:
		var grab_point_hand := _active_grab_point as XRToolsGrabPointHand
		if grab_point_hand and grab_point_hand.hand_pose:
			by_hand.add_pose_override(self, GRIP_POSE_PRIORITY, grab_point_hand.hand_pose)

	# If we have been picked up by a collision hand then add collision
	# exceptions to prevent the hand and pickable colliding.
	if by_collision_hand:
		add_collision_exception_with(by_collision_hand)
		by_collision_hand.add_collision_exception_with(self)

	# Remember the mode before pickup
	match release_mode:
		ReleaseMode.UNFROZEN:
			restore_freeze = false

		ReleaseMode.FROZEN:
			restore_freeze = true

		_:
			restore_freeze = freeze

	# turn off physics on our pickable object
	freeze = true
	collision_layer = picked_up_layer
	collision_mask = 0

	if by.picked_up_ranged:
		if ranged_grab_method == RangedMethod.LERP:
			_start_ranged_grab()
		else:
			_do_snap_grab()
	elif _active_grab_point:
		_do_snap_grab()
	else:
		_do_precise_grab()


# Called when this object is dropped
func let_go(p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	# Skip if idle
	if _state == PickableState.IDLE:
		return

	# If held then detach from holder
	if _state == PickableState.HELD:
		match hold_method:
			HoldMethod.REPARENT:
				var original_transform = global_transform
				picked_up_by.remove_child(self)
				original_parent.add_child(self)
				global_transform = original_transform

			HoldMethod.REMOTE_TRANSFORM:
				_remote_transform.remote_path = NodePath()
				_remote_transform.queue_free()
				_remote_transform = null

	# Restore RigidBody mode
	freeze = restore_freeze
	collision_mask = original_collision_mask
	collision_layer = original_collision_layer

	# Set velocity
	linear_velocity = p_linear_velocity
	angular_velocity = p_angular_velocity

	# If we are held by a hand then remove any hand-pose-override we may have
	# given it.
	if by_hand:
		by_hand.remove_pose_override(self)

	# If we are held by a cillision hand then remove any collision exceptions
	# we may have added.
	if by_collision_hand:
		remove_collision_exception_with(by_collision_hand)
		by_collision_hand.remove_collision_exception_with(self)

	# we are no longer picked up
	_state = PickableState.IDLE
	picked_up_by = null
	by_controller = null
	by_hand = null
	by_collision_hand = null
	hold_node = null

	# Stop any XRToolsMoveTo being used for remote grabbing
	if _move_to:
		_move_to.stop()
		_move_to.queue_free()
		_move_to = null

	# let interested parties know
	emit_signal("dropped", self)


## Get the controller currently holding this object
func get_picked_up_by_controller() -> XRController3D:
	return by_controller


## Get the hand currently holding this object
func get_picked_up_by_hand() -> XRToolsHand:
	return by_hand


## Get the active grab-point this object is held by
func get_active_grab_point() -> XRToolsGrabPoint:
	return _active_grab_point


## Switch the active grab-point for this object
func switch_active_grab_point(grab_point : XRToolsGrabPoint):
	# Verify switching from one grab point to another
	if not _active_grab_point or not grab_point or _state != PickableState.HELD:
		return

	# Set the new active grab-point
	_active_grab_point = grab_point

	# Update the hold transform
	match hold_method:
		HoldMethod.REMOTE_TRANSFORM:
			# Update the remote transform
			_remote_transform.transform = _active_grab_point.transform.inverse()

		HoldMethod.REPARENT:
			# Update our transform
			transform = _active_grab_point.global_transform.inverse() * global_transform

	# Update the pose
	if by_hand and _active_grab_point:
		var grab_point_hand := _active_grab_point as XRToolsGrabPointHand
		if grab_point_hand and grab_point_hand.hand_pose:
			by_hand.add_pose_override(self, GRIP_POSE_PRIORITY, grab_point_hand.hand_pose)
		else:
			by_hand.remove_pose_override(self)


func _start_ranged_grab() -> void:
	# Set state to grabbing at range and enable processing
	_state = PickableState.GRABBING_RANGED

	# Calculate the transform offset
	var offset : Transform3D
	if _active_grab_point:
		offset = _active_grab_point.transform.inverse()
	else:
		offset = Transform3D.IDENTITY

	# Create a XRToolsMoveTo to perform the remote-grab. The remote grab will move
	# us to the pickup object at the ranged-grab speed, and also takes into account
	# the center-pickup position
	_move_to = XRToolsMoveTo.new()
	_move_to.start(self, hold_node, offset, ranged_grab_speed)
	_move_to.move_complete.connect(_ranged_grab_complete)
	self.add_child(_move_to)


func _ranged_grab_complete() -> void:
	# Discard the XRToolsMoveTo performing the remote-grab
	_move_to.queue_free()
	_move_to = null

	# Perform the snap grab
	_do_snap_grab()


func _do_snap_grab() -> void:
	# Set state to held
	_state = PickableState.HELD

	# Perform the hold
	match hold_method:
		HoldMethod.REMOTE_TRANSFORM:
			# Calculate the snap transform for remote-transforming
			var snap_transform: Transform3D
			if _active_grab_point:
				snap_transform = _active_grab_point.transform.inverse()
			else:
				snap_transform = Transform3D.IDENTITY

			# Construct the remote transform
			_remote_transform = RemoteTransform3D.new()
			_remote_transform.set_name("PickupRemoteTransform")
			hold_node.add_child(_remote_transform)
			_remote_transform.transform = snap_transform
			_remote_transform.remote_path = _remote_transform.get_path_to(self)

		HoldMethod.REPARENT:
			# Calculate the snap transform for reparenting
			var snap_transform: Transform3D
			if _active_grab_point:
				snap_transform = _active_grab_point.global_transform.inverse() * global_transform
			else:
				snap_transform = Transform3D.IDENTITY

			# Reparent to the holder with snap transform
			original_parent.remove_child(self)
			hold_node.add_child(self)
			transform = snap_transform

	# Emit the picked up signal
	emit_signal("picked_up", self)


func _do_precise_grab() -> void:
	# Set state to held
	_state = PickableState.HELD

	# Reparent to the holder
	match hold_method:
		HoldMethod.REMOTE_TRANSFORM:
			# Calculate the precise transform for remote-transforming
			var precise_transform = hold_node.global_transform.inverse() * global_transform

			# Construct the remote transform
			_remote_transform = RemoteTransform3D.new()
			_remote_transform.set_name("PickupRemoteTransform")
			hold_node.add_child(_remote_transform)
			_remote_transform.transform = hold_node.global_transform.inverse() * global_transform
			_remote_transform.remote_path = _remote_transform.get_path_to(self)

		HoldMethod.REPARENT:
			# Calculate the precise transform for reparenting
			var precise_transform = global_transform

			# Reparent to the holder with precise transform
			original_parent.remove_child(self)
			hold_node.add_child(self)
			global_transform = precise_transform

	# Emit the picked up signal
	emit_signal("picked_up", self)


## Find the first grab-point for the grabber
func _get_grab_point(_grabber : Node) -> XRToolsGrabPoint:
	# Iterate over all grab points
	for g in _grab_points:
		var grab_point : XRToolsGrabPoint = g
		if grab_point.can_grab(_grabber):
			return grab_point

	# No suitable grab-point found
	return null


func _set_ranged_grab_method(new_value: int) -> void:
	ranged_grab_method = new_value
	can_ranged_grab = new_value != RangedMethod.NONE
