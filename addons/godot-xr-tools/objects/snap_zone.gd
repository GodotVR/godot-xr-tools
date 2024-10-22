@tool
class_name XRToolsSnapZone
extends Area3D


## Signal emitted when the snap-zone picks something up
signal has_picked_up(what)

## Signal emitted when the snap-zone drops something
signal has_dropped

# Signal emitted when the highlight state changes
signal highlight_updated(pickable, enable)

# Signal emitted when the highlight state changes
signal close_highlight_updated(pickable, enable)


## Enumeration of snap mode
enum SnapMode {
	DROPPED,	## Snap only when the object is dropped
	RANGE,		## Snap whenever an object is in range
}


## Enable or disable snap-zone
@export var enabled : bool = true: set = _set_enabled

## Optional audio stream to play when a object snaps to the zone
@export var stash_sound : AudioStream

## Grab distance
@export var grab_distance : float = 0.3: set = _set_grab_distance

## Snap mode
@export var snap_mode : SnapMode = SnapMode.DROPPED: set = _set_snap_mode

## Require snap items to be in specified group
@export var snap_require : String = ""

## Deny snapping items in the specified group
@export var snap_exclude : String = ""

## Require grab-by to be in the specified group
@export var grab_require : String = ""

## Deny grab-by
@export var grab_exclude : String= ""

## Initial object in snap zone
@export var initial_object : NodePath


# Public fields
var closest_object : Node3D = null
var picked_up_object : Node3D = null
var picked_up_ranged : bool = true


# Private fields
var _object_in_grab_area = Array()


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsSnapZone"


func _ready():
	# Set collision shape radius
	if has_node("CollisionShape3D") and "radius" in $CollisionShape3D.shape:
		$CollisionShape3D.shape.radius = grab_distance

	# Add important connections
	if not body_entered.is_connected(_on_snap_zone_body_entered):
		body_entered.connect(_on_snap_zone_body_exited)
	if not body_exited.is_connected(_on_snap_zone_body_exited):
		body_exited.connect(_on_snap_zone_body_exited)

	# Perform updates
	_update_snap_mode()

	# Perform the initial object check when next idle
	if not Engine.is_editor_hint():
		_initial_object_check.call_deferred()


# Called on each frame to update the pickup
func _process(_delta):
	# Skip if in editor or not enabled
	if Engine.is_editor_hint() or not enabled:
		return

	# Skip if we aren't doing range-checking
	if snap_mode != SnapMode.RANGE:
		return

	# Skip if already holding a valid object
	if is_instance_valid(picked_up_object):
		return

	# Check for any object in range that can be grabbed
	for o in _object_in_grab_area:
		# skip objects that can not be picked up
		if not o.can_pick_up(self):
			continue

		# pick up our target
		pick_up_object(o)
		return


# Pickable Method: snap-zone can be grabbed if holding object
func can_pick_up(by: Node3D) -> bool:
	# Refuse if not enabled
	if not enabled:
		return false

	# Refuse if no object is held
	if not is_instance_valid(picked_up_object):
		return false

	# Refuse if the grab-by is not in the required group
	if not grab_require.is_empty() and not by.is_in_group(grab_require):
		return false

	# Refuse if the grab-by is in the excluded group
	if not grab_exclude.is_empty() and by.is_in_group(grab_exclude):
		return false

	# Grab is permitted
	return true


# Pickable Method: Snap points can't be picked up
func is_picked_up() -> bool:
	return false


# Pickable Method: Gripper-actions can't occur on snap zones
func action():
	pass


# Ignore highlighting requests from XRToolsFunctionPickup
func request_highlight(from : Node, on : bool = true) -> void:
	if is_instance_valid(picked_up_object):
		picked_up_object.request_highlight(from, on)


# Pickable Method: Object being grabbed from this snap zone
func pick_up(_by: Node3D) -> void:
	pass


# Pickable Method: Player never graps snap-zone
func let_go(_by: Node3D, _p_linear_velocity: Vector3, _p_angular_velocity: Vector3) -> void:
	pass


# Pickup Method: Drop the currently picked up object
func drop_object() -> void:
	if not is_instance_valid(picked_up_object):
		return

	# let go of this object
	picked_up_object.let_go(self, Vector3.ZERO, Vector3.ZERO)
	picked_up_object = null
	has_dropped.emit()
	highlight_updated.emit(self, enabled)


# Check for an initial object pickup
func _initial_object_check() -> void:
	# Check for an initial object
	if initial_object:
		# Force pick-up the initial object
		pick_up_object(get_node(initial_object))
	else:
		# Show highlight when empty and enabled
		highlight_updated.emit(self, enabled)


# Called when a body enters the snap zone
func _on_snap_zone_body_entered(target: Node3D) -> void:
	# Ignore objects already known about
	if _object_in_grab_area.find(target) >= 0:
		return

	# Reject objects which don't support picking up
	if not target.has_method('pick_up'):
		return

	# Reject objects not in the required snap group
	if not snap_require.is_empty() and not target.is_in_group(snap_require):
		return

	# Reject objects in the excluded snap group
	if not snap_exclude.is_empty() and target.is_in_group(snap_exclude):
		return

	# Reject climbable objects
	if target is XRToolsClimbable:
		return

	# Add to the list of objects in grab area
	_object_in_grab_area.push_back(target)

	# If this snap zone is configured to snap objects that are dropped, then
	# start listening for the objects dropped signal
	if snap_mode == SnapMode.DROPPED and target.has_signal("dropped"):
		target.connect("dropped", _on_target_dropped, CONNECT_DEFERRED)

	# Show highlight when something could be snapped
	if not is_instance_valid(picked_up_object):
		close_highlight_updated.emit(self, enabled)


# Called when a body leaves the snap zone
func _on_snap_zone_body_exited(target: Node3D) -> void:
	# Ensure the object is not in our list
	_object_in_grab_area.erase(target)

	# Stop listening for dropped signals
	if target.has_signal("dropped") and target.is_connected("dropped", _on_target_dropped):
		target.disconnect("dropped", _on_target_dropped)

	# Hide highlight when nothing could be snapped
	if _object_in_grab_area.is_empty():
		close_highlight_updated.emit(self, false)


# Test if this snap zone has a picked up object
func has_snapped_object() -> bool:
	return is_instance_valid(picked_up_object)


# Pick up the specified object
func pick_up_object(target: Node3D) -> void:
	# check if already holding an object
	if is_instance_valid(picked_up_object):
		# skip if holding the target object
		if picked_up_object == target:
			return
		# holding something else? drop it
		drop_object()

	# skip if target null or freed
	if not is_instance_valid(target):
		return

	# Pick up our target. Note, target may do instant drop_and_free
	picked_up_object = target
	if has_node("AudioStreamPlayer3D"):
		var player = get_node("AudioStreamPlayer3D")
		if is_instance_valid(player):
			if player.playing:
				player.stop()
			player.stream = stash_sound
			player.play()

	target.pick_up(self)

	# If object picked up then emit signal
	if is_instance_valid(picked_up_object):
		has_picked_up.emit(picked_up_object)
		highlight_updated.emit(self, false)


# Called when the enabled property has been modified
func _set_enabled(p_enabled: bool) -> void:
	enabled = p_enabled
	if is_inside_tree:
		highlight_updated.emit(
			self,
			enabled and not is_instance_valid(picked_up_object))


# Called when the grab distance has been modified
func _set_grab_distance(new_value: float) -> void:
	grab_distance = new_value
	if is_inside_tree() and $CollisionShape3D:
		$CollisionShape3D.shape.radius = grab_distance


# Called when the snap mode property has been modified
func _set_snap_mode(new_value: SnapMode) -> void:
	snap_mode = new_value
	if is_inside_tree():
		_update_snap_mode()


# Handle changes to the snap mode
func _update_snap_mode() -> void:
	match snap_mode:
		SnapMode.DROPPED:
			# Disable _process as we aren't using RANGE pickups
			set_process(false)

			# Start monitoring all objects in range for drop
			for o in _object_in_grab_area:
				o.connect("dropped", _on_target_dropped, CONNECT_DEFERRED)

		SnapMode.RANGE:
			# Enable _process to scan for RANGE pickups
			set_process(true)

			# Clear any dropped signal hooks
			for o in _object_in_grab_area:
				o.disconnect("dropped", _on_target_dropped)


# Called when a target in our grab area is dropped
func _on_target_dropped(target: Node3D) -> void:
	# Skip if not enabled
	if not enabled:
		return

	# Skip if already holding a valid object
	if is_instance_valid(picked_up_object):
		return

	# Skip if the target is not valid
	if not is_instance_valid(target):
		return

	# Pick up the target if we can
	if target.can_pick_up(self):
		pick_up_object(target)
