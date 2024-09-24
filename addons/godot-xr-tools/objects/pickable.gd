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


# Signal emitted when this object is picked up (held by a player or snap-zone)
signal picked_up(pickable)

# Signal emitted when this object is dropped
signal dropped(pickable)

# Signal emitted when this object is grabbed (primary or secondary)
signal grabbed(pickable, by)

# Signal emitted when this object is released (primary or secondary)
signal released(pickable, by)

# Signal emitted when the user presses the action button while holding this object
signal action_pressed(pickable)

# Signal emitted when the user releases the action button while holding this object
signal action_released(pickable)

# Signal emitted when the highlight state changes
signal highlight_updated(pickable, enable)


## Method used to grab object at range
enum RangedMethod {
	NONE,				## Ranged grab is not supported
	SNAP,				## Object snaps to holder
	LERP,				## Object lerps to holder
}

enum ReleaseMode {
	ORIGINAL = -1,		## Preserve original mode when picked up
	UNFROZEN = 0,		## Release and unfreeze
	FROZEN = 1,			## Release and freeze
}

enum SecondHandGrab {
	IGNORE,				## Ignore second grab
	SWAP,				## Swap to second hand
	SECOND,				## Second hand grab
}


# Default layer for held objects is 17:held-object
const DEFAULT_LAYER := 0b0000_0000_0000_0001_0000_0000_0000_0000


## If true, the pickable supports being picked up
@export var enabled : bool = true

## If true, the grip control must be held to keep the object picked up
@export var press_to_hold : bool = true

## Layer for this object while picked up
@export_flags_3d_physics var picked_up_layer : int = DEFAULT_LAYER

## Release mode to use when releasing the object
@export var release_mode : ReleaseMode = ReleaseMode.ORIGINAL

## Method used to perform a ranged grab
@export var ranged_grab_method : RangedMethod = RangedMethod.SNAP: set = _set_ranged_grab_method

## Second hand grab mode
@export var second_hand_grab : SecondHandGrab = SecondHandGrab.IGNORE

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

# Count of 'is_closest' grabbers
var _closest_count: int = 0

# Grab Driver to control position while grabbed
var _grab_driver: XRToolsGrabDriver = null

# Array of grab points
var _grab_points : Array[XRToolsGrabPoint] = []

# Dictionary of nodes requesting highlight
var _highlight_requests : Dictionary = {}

# Is this node highlighted
var _highlighted : bool = false


# Remember some state so we can return to it when the user drops the object
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


# Called when the node exits the tree
func _exit_tree():
	# Skip if not picked up
	if not is_instance_valid(_grab_driver):
		return

	# Release primary grab
	if _grab_driver.primary:
		_grab_driver.primary.release()

	# Release secondary grab
	if _grab_driver.secondary:
		_grab_driver.secondary.release()


# Test if this object can be picked up
func can_pick_up(by: Node3D) -> bool:
	# Refuse if not enabled
	if not enabled:
		return false

	# Allow if not held by anything
	if not is_picked_up():
		return true

	# Fail if second hand grabbing isn't allowed
	if second_hand_grab == SecondHandGrab.IGNORE:
		return false

	# Fail if either pickup isn't by a hand
	if not _grab_driver.primary.pickup or not by is XRToolsFunctionPickup:
		return false

	# Allow second hand grab
	return true


# Test if this object is picked up
func is_picked_up() -> bool:
	return _grab_driver and _grab_driver.primary


# action is called when user presses the action button while holding this object
func action():
	# let interested parties know
	action_pressed.emit(self)


func controller_action(controller : XRController3D):
	# Let the grab points know about the action
	if (
		_grab_driver.primary and _grab_driver.primary.point
		and _grab_driver.primary.controller == controller
	):
		_grab_driver.primary.point.action(self)

	if (
		_grab_driver.secondary and _grab_driver.secondary.point
		and _grab_driver.secondary.controller == controller
	):
		_grab_driver.secondary.point.action(self)


# action_release is called when user releases the action button while holding this object
func action_release():
	# let interested parties know
	action_released.emit(self)


func controller_action_release(controller : XRController3D):
	# Let the grab points know about the action release
	if (
		_grab_driver.primary and _grab_driver.primary.point
		and _grab_driver.primary.controller == controller
	):
		_grab_driver.primary.point.action_release(self)

	if (
		_grab_driver.secondary and _grab_driver.secondary.point
		and _grab_driver.secondary.controller == controller
	):
		_grab_driver.secondary.point.action_release(self)


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
		highlight_updated.emit(self, _highlighted)


func drop():
	# Skip if not picked up
	if not is_picked_up():
		return

	# Request secondary grabber to drop
	if _grab_driver.secondary:
		_grab_driver.secondary.by.drop_object()

	# Request primary grabber to drop
	_grab_driver.primary.by.drop_object()


func drop_and_free():
	drop()
	queue_free()


# Called when this object is picked up
func pick_up(by: Node3D) -> void:
	# Skip if not enabled
	if not enabled:
		return

	# Find the grabber information
	var grabber := Grabber.new(by)

	# Test if we're already picked up:
	if is_picked_up():
		# Ignore if we don't support second-hand grab
		if second_hand_grab == SecondHandGrab.IGNORE:
			print_verbose("%s> second-hand grab not enabled" % name)
			return

		# Ignore if either pickup isn't by a hand
		if not _grab_driver.primary.pickup or not grabber.pickup:
			return

		# Construct the second grab
		if second_hand_grab != SecondHandGrab.SWAP:
			# Grab the object
			var by_grab_point := _get_grab_point(by, _grab_driver.primary.point)
			var grab := Grab.new(grabber, self, by_grab_point, true)
			_grab_driver.add_grab(grab)

			# Report the secondary grab
			grabbed.emit(self, by)
			return

		# Swapping hands, let go with the primary grab
		print_verbose("%s> letting go to swap hands" % name)
		let_go(_grab_driver.primary.by, Vector3.ZERO, Vector3.ZERO)

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

	# Find a suitable primary hand grab
	var by_grab_point := _get_grab_point(by, null)

	# Construct the grab driver
	if by.picked_up_ranged:
		if ranged_grab_method == RangedMethod.LERP:
			var grab := Grab.new(grabber, self, by_grab_point, false)
			_grab_driver = XRToolsGrabDriver.create_lerp(self, grab, ranged_grab_speed)
		else:
			var grab := Grab.new(grabber, self, by_grab_point, false)
			_grab_driver = XRToolsGrabDriver.create_snap(self, grab)
	else:
		var grab := Grab.new(grabber, self, by_grab_point, true)
		_grab_driver = XRToolsGrabDriver.create_snap(self, grab)

	# Report picked up and grabbed
	picked_up.emit(self)
	grabbed.emit(self, by)


# Called when this object is dropped
func let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	# Skip if not picked up
	if not is_picked_up():
		return

	# Get the grab information
	var grab := _grab_driver.get_grab(by)
	if not grab:
		return

	# Remove the grab from the driver and release the grab
	_grab_driver.remove_grab(grab)
	grab.release()

	# Test if still grabbing
	if _grab_driver.primary:
		# Test if we need to swap grab-points
		if is_instance_valid(_grab_driver.primary.hand_point):
			# Verify the current primary grab point is a valid primary grab point
			if _grab_driver.primary.hand_point.mode != XRToolsGrabPointHand.Mode.SECONDARY:
				return

			# Find a more suitable grab-point
			var new_grab_point := _get_grab_point(_grab_driver.primary.by, null)
			print_verbose("%s> held only by secondary, swapping grab points" % name)
			switch_active_grab_point(new_grab_point)

		# Grab is still good
		return

	# Drop the grab-driver
	print_verbose("%s> dropping" % name)
	_grab_driver.discard()
	_grab_driver = null

	# Restore RigidBody mode
	freeze = restore_freeze
	collision_mask = original_collision_mask
	collision_layer = original_collision_layer

	# Set velocity
	linear_velocity = p_linear_velocity
	angular_velocity = p_angular_velocity

	# let interested parties know
	dropped.emit(self)


## Get the node currently holding this object
func get_picked_up_by() -> Node3D:
	# Skip if not picked up
	if not is_picked_up():
		return null

	# Get the primary pickup
	return _grab_driver.primary.by


## Get the controller currently holding this object
func get_picked_up_by_controller() -> XRController3D:
	# Skip if not picked up
	if not is_picked_up():
		return null

	# Get the primary pickup controller
	return _grab_driver.primary.controller


## Get the active grab-point this object is held by
func get_active_grab_point() -> XRToolsGrabPoint:
	# Skip if not picked up
	if not is_picked_up():
		return null

	return _grab_driver.primary.point


## Switch the active grab-point for this object
func switch_active_grab_point(grab_point : XRToolsGrabPoint):
	# Skip if not picked up
	if not is_picked_up():
		return null

	# Apply the grab point
	_grab_driver.primary.set_grab_point(grab_point)


## Find the most suitable grab-point for the grabber
func _get_grab_point(grabber : Node3D, current : XRToolsGrabPoint) -> XRToolsGrabPoint:
	# Find the best grab-point
	var fitness := 0.0
	var point : XRToolsGrabPoint = null
	for p in _grab_points:
		var f := p.can_grab(grabber, current)
		if f > fitness:
			fitness = f
			point = p

	# Resolve redirection
	while point is XRToolsGrabPointRedirect:
		point = point.target

	# Return the best grab point
	print_verbose("%s> picked grab-point %s" % [name, point])
	return point


func _set_ranged_grab_method(new_value: int) -> void:
	ranged_grab_method = new_value
	can_ranged_grab = new_value != RangedMethod.NONE
