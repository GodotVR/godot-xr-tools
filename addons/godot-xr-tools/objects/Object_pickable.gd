tool
class_name XRToolsPickable
extends RigidBody


##
## Pickable Object
##
## @desc:
##     This script manages a RigidBody that supports being picked up.
##


# Signal emitted when the user picks up this object
signal picked_up(pickable)

# Signal emitted when the user drops this object
signal dropped(pickable)

# Signal emitted when the user presses the action button while holding this object
signal action_pressed(pickable)

# Signal emitted when the highlight state changes
signal highlight_updated(pickable, enable)


# Method used to hold object
enum HoldMethod {
	REMOTE_TRANSFORM,	# Remote transform to holder
	REPARENT,			# Reparent to holder
}

# Method used to grab object at range
enum RangedMethod {
	NONE,				# Not supported
	SNAP,				# Snap to holder
	LERP,				# Lerp to holder
}

# Current pickable object state
enum PickableState {
	IDLE,				# Object not held
	GRABBING_RANGED,	# Object being grabbed at range
	HELD,				# Object held
}


## Flag indicating if the grip control must be held
export (bool) var press_to_hold = true

## Flag indicating transform should be reset to pickup center
export (bool) var reset_transform_on_pickup = true

## Layer for this object while picked up
export (int, LAYERS_3D_PHYSICS) var picked_up_layer = 0

## Method used to hold an object
export (HoldMethod) var hold_method = HoldMethod.REMOTE_TRANSFORM

## Method used to perform a ranged grab
export (RangedMethod) var ranged_grab_method = RangedMethod.SNAP setget _set_ranged_grab_method

## Speed for ranged grab
export var ranged_grab_speed: float = 20.0

## Refuse pick-by when in the specified group
export var picked_by_exclude: String = ""

## Require pick-by to be in the specified group
export var picked_by_require: String = ""


# Can object be grabbed at range
var can_ranged_grab: bool = true

# Original RigidBody mode
var original_mode

# Entity holding this item
var picked_up_by: Spatial = null

# Controller holding this item (may be null if held by snap-zone)
var by_controller: ARVRController = null

# Pickup center
var center_pickup_on_node: Spatial = null

# Count of 'is_closest' grabbers
var _closest_count: int = 0

# Current state
var _state = PickableState.IDLE

# Remote transform
var _remote_transform: RemoteTransform = null


# Remember some state so we can return to it when the user drops the object
onready var original_parent = get_parent()
onready var original_collision_mask: int = collision_mask
onready var original_collision_layer: int = collision_layer


# Called when the node enters the scene tree for the first time.
func _ready():
	# Attempt to get the pickup center if provided
	center_pickup_on_node = get_node_or_null("PickupCenter")


# Called to process the current frame
func _process(delta: float) -> void:
	# If not performing a ranged grab then shut down processing
	if _state != PickableState.GRABBING_RANGED:
		set_process(false)
		return

	# Lerp to holder
	var move := picked_up_by.global_transform.origin - global_transform.origin
	var move_length := move.length()
	var step := ranged_grab_speed * delta
	if step >= move_length:
		_do_snap_grab()
	else:
		global_transform.origin += move * step / move_length


# Test if this object can be picked up
func can_pick_up(_by: Spatial) -> bool:
	return _state == PickableState.IDLE


# Test if this object is picked up
func is_picked_up():
	return _state == PickableState.HELD


# action is called when user presses the action button while holding this object
func action():
	# let interested parties know
	emit_signal("action_pressed", self)


# This method is invoked when it becomes the closest pickable object to one of
# the pickup functions.
func increase_is_closest():
	# Increment the closest counter
	_closest_count += 1

	# If this object has just become highlighted then emit the signal
	if _closest_count == 1:
		emit_signal("highlight_updated", self, true)


# This method is invoked when it stops being the closest pickable object to one
# of the pickup functions.
func decrease_is_closest():
	# Decrement the closest counter
	_closest_count -= 1

	# If no-longer highlighted then emit the signal
	if _closest_count == 0:
		emit_signal("highlight_updated", self, false)


func drop_and_free():
	if picked_up_by:
		picked_up_by.drop_object()

	queue_free()


# Called when this object is picked up
func pick_up(by: Spatial, with_controller: ARVRController) -> void:
	# Skip if not idle
	if _state != PickableState.IDLE:
		return

	if picked_up_by:
		let_go(Vector3.ZERO, Vector3.ZERO)

	# remember who picked us up
	picked_up_by = by
	by_controller = with_controller

	# Remember the mode before pickup
	original_mode = mode

	# turn off physics on our pickable object
	mode = RigidBody.MODE_STATIC
	collision_layer = picked_up_layer
	collision_mask = 0

	if by.picked_up_ranged:
		if ranged_grab_method == RangedMethod.LERP:
			_start_ranged_grab()
		else:
			_do_snap_grab()
	elif reset_transform_on_pickup:
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
				_remote_transform.queue_free()
				_remote_transform = null

	# Restore RigidBody mode
	mode = original_mode
	collision_mask = original_collision_mask
	collision_layer = original_collision_layer

	# Set velocity
	linear_velocity = p_linear_velocity
	angular_velocity = p_angular_velocity

	# we are no longer picked up
	_state = PickableState.IDLE
	picked_up_by = null
	by_controller = null

	# let interested parties know
	emit_signal("dropped", self)


func _start_ranged_grab() -> void:
	# Set state to grabbing at range and enable processing
	_state = PickableState.GRABBING_RANGED
	set_process(true)


func _do_snap_grab() -> void:
	# Set state to held
	_state = PickableState.HELD
	set_process(false)

	# Perform the hold
	match hold_method:
		HoldMethod.REMOTE_TRANSFORM:
			# Calculate the snap transform for remote-transforming
			var snap_transform: Transform
			if center_pickup_on_node:
				snap_transform = center_pickup_on_node.transform
			else:
				snap_transform = Transform()

			# Construct the remote transform
			_remote_transform = RemoteTransform.new()
			_remote_transform.set_name("PickupRemoteTransform")
			picked_up_by.add_child(_remote_transform)
			_remote_transform.transform = snap_transform
			_remote_transform.remote_path = _remote_transform.get_path_to(self)

		HoldMethod.REPARENT:
			# Calculate the snap transform for reparenting
			var snap_transform: Transform
			if center_pickup_on_node:
				snap_transform = center_pickup_on_node.global_transform.inverse() * global_transform
			else:
				snap_transform = Transform()

			# Reparent to the holder with snap transform
			original_parent.remove_child(self)
			picked_up_by.add_child(self)
			transform = snap_transform

	# Emit the picked up signal
	emit_signal("picked_up", self)


func _do_precise_grab() -> void:
	# Set state to held
	_state = PickableState.HELD
	set_process(false)

	# Reparent to the holder
	match hold_method:
		HoldMethod.REMOTE_TRANSFORM:
			# Calculate the precise transform for remote-transforming
			var precise_transform = picked_up_by.global_transform.inverse() * global_transform

			# Construct the remote transform
			_remote_transform = RemoteTransform.new()
			_remote_transform.set_name("PickupRemoteTransform")
			picked_up_by.add_child(_remote_transform)
			_remote_transform.transform = picked_up_by.global_transform.inverse() * global_transform
			_remote_transform.remote_path = _remote_transform.get_path_to(self)

		HoldMethod.REPARENT:
			# Calculate the precise transform for reparenting
			var precise_transform = global_transform

			# Reparent to the holder with precise transform
			original_parent.remove_child(self)
			picked_up_by.add_child(self)
			global_transform = precise_transform

	# Emit the picked up signal
	emit_signal("picked_up", self)


func _set_ranged_grab_method(new_value: int) -> void:
	ranged_grab_method = new_value
	can_ranged_grab = new_value != RangedMethod.NONE


func _get_configuration_warning():
	# Check for error cases when missing a PickupCenter
	if not find_node("PickupCenter"):
		if reset_transform_on_pickup:
			return "Missing PickupCenter child node for 'reset transform on pickup'"
		if ranged_grab_method != RangedMethod.NONE:
			return "Missing PickupCenter child node for 'remote grabbing'"

	# No issues found
	return ""
