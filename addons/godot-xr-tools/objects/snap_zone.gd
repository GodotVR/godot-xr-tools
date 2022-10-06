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


## Grab distance
@export var grab_distance : float = 0.3 :
	set(new_value):
		grab_distance = new_value
		if is_inside_tree() and $CollisionShape:
			$CollisionShape.shape.radius = grab_distance
		
## Require snap items to be in specified group
@export var snap_require : String = ""

## Deny snapping items in the specified group
@export var snap_exclude : String = ""

## Require grab-by to be in the specified group
@export var grab_require : String = ""

## Deny grab-by
@export var grab_exclude : String= ""


# Public fields
var closest_object : Node3D = null
var picked_up_object : Node3D = null
var picked_up_ranged : bool = true


# Private fields
var _object_in_grab_area = Array()


func _ready():
	# Set collision shape radius
	$CollisionShape3D.shape.radius = grab_distance

	# Show highlight when empty
	emit_signal("highlight_updated", self, true)


# Called on each frame to update the pickup
func _process(_delta):
	if is_instance_valid(picked_up_object):
		return

	for o in _object_in_grab_area:
		# skip objects that can not be picked up
		if not o.can_pick_up(self):
			continue

		# pick up our target
		_pick_up_object(o)
		return


# Pickable Method: snap-zone can be grabbed if holding object
func can_pick_up(by: Node3D) -> bool:
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


# Pickable Method: Ignore snap-zone proximity to grippers
func increase_is_closest():
	pass


# Pickable Method: Ignore snap-zone proximity to grippers
func decrease_is_closest():
	pass


# Pickable Method: Object being grabbed from this snap zone
func pick_up(_by: Node3D, _with_controller: XRController3D) -> void:
	pass


# Pickable Method: Player never graps snap-zone
func let_go(_p_linear_velocity: Vector3, _p_angular_velocity: Vector3) -> void:
	pass


# Pickup Method: Drop the currently picked up object
func drop_object() -> void:
	if not is_instance_valid(picked_up_object):
		return

	# let go of this object
	picked_up_object.let_go(Vector3.ZERO, Vector3.ZERO)
	picked_up_object = null
	emit_signal("has_dropped")
	emit_signal("highlight_updated", self, true)


func _on_snap_zone_body_entered(target: Node3D) -> void:
	# Ignore objects already in area
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

	# Show highlight when something could be snapped
	if not is_instance_valid(picked_up_object):
		emit_signal("close_highlight_updated", self, true)


func _on_snap_zone_body_exited(target: Node3D) -> void:
	_object_in_grab_area.erase(target)

	# Hide highlight when nothing could be snapped
	if _object_in_grab_area.is_empty():
		emit_signal("close_highlight_updated", self, false)


# Pick up the specified object
func _pick_up_object(target: Node3D) -> void:
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
	target.pick_up(self, null)

	# If object picked up then emit signal
	if is_instance_valid(picked_up_object):
		emit_signal("has_picked_up", picked_up_object)
		emit_signal("highlight_updated", self, false)
