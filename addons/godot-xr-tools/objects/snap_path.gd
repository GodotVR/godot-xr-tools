@tool
class_name XRToolsSnapPath
extends XRToolsSnapZone


## An [XRToolsSnapZone] that allows [XRToolsPickable] to be placed along a
## child [Path3D] node. They can either be placed along any point in the curve
## or at discrete intervals by setting "snap_interval" above '0.0'.
##
## Note: Attached [XRToolsPickable]s will face the +Z axis.


## Real world distance between intervals in Meters.
## Enabled when not 0
@export  var snap_interval := 0.0:
	set(v): snap_interval = absf(v)

@onready var path : Path3D


func _ready() -> void:
	super._ready()

	for c in get_children():
		if c is Path3D:
			path = c
			break


func has_snap_interval() -> bool:
	return !is_equal_approx(snap_interval, 0.0)


func _get_configuration_warnings() -> PackedStringArray:
	# Check for Path3D child
	for c in get_children():
		if c is Path3D:
			path = c
			return[]
	return["This node requires a Path3D child node to define its shape."]


# Called when a target in our grab area is dropped
func _on_target_dropped(target: Node3D) -> void:
	# Skip if invalid
	if !enabled or !path or !target.can_pick_up(self) or \
		!is_instance_valid(target) or \
		is_instance_valid(picked_up_object):
		return

	# Make a zone that will destruct once its object has left
	var zone   = _make_temp_zone()
	var offset = _find_offset(path, target.global_position)

	# if snap guide
	if _has_snap_guide(target):
		# comply with guide
		offset = _find_closest_offset_with_length(path.curve, offset, _get_snap_guide(target).length)

		# too large to place on path
		if is_equal_approx(offset, -1.0):
			return

	# if snap_interval has been set, use it
	if has_snap_interval():
		offset = snappedf(offset, snap_interval)

	# set position
	zone.position = path.curve.sample_baked(offset)

	# Add zone as a child
	path.add_child(zone)
	zone.owner = path

	# Connect self-destruct with lambda
	zone.has_dropped.connect(func(): zone.queue_free(), Object.ConnectFlags.CONNECT_ONE_SHOT)

	# Use Pickable's Shapes as our Shapes
	for c in target.get_children():
		if c is CollisionShape3D:
			PhysicsServer3D.area_add_shape(zone.get_rid(), c.shape.get_rid(), c.transform)

	# Force pickup
	zone.pick_up_object(target)


# Make a zone that dies on dropping objects
func _make_temp_zone():
	var zone = XRToolsSnapZone.new()

	# connect lambda to play stash sounds when temp zone picks up
	if has_node("AudioStreamPlayer3D"):
		zone.has_picked_up.connect(\
		func(object):\
			$AudioStreamPlayer3D.stream = stash_sound;\
			$AudioStreamPlayer3D.play()\
		)

	# XRToolsSnapZone manaul copy
	zone.enabled        = true
	zone.stash_sound    = stash_sound
	zone.grab_distance  = grab_distance
	zone.snap_mode      = snap_mode
	zone.snap_require   = snap_require
	zone.snap_exclude   = snap_exclude
	zone.grab_require   = grab_require
	zone.grab_exclude   = grab_exclude
	zone.initial_object = NodePath()

	# CollisionObject3D manual copy
	zone.disable_mode       = disable_mode
	zone.collision_layer    = collision_layer
	zone.collision_mask     = collision_mask
	zone.collision_priority = collision_priority

	return zone


func _has_snap_guide(target: Node3D) -> bool:
	for c in target.get_children():
		if c is XRToolsSnapPathGuide:
			return true
	return false


func _get_snap_guide(target: Node3D) -> Node3D:
	for c in target.get_children():
		if c is XRToolsSnapPathGuide:
			return c
	return null


# Returns -1 if invalid
# _offset should be in _curve's local coordinates
func _find_closest_offset_with_length(_curve: Curve3D, _offset: float, _length: float) -> float:
	# p1 and p2 are the object's start and end respectively
	var p1      = _offset
	var p2      = _offset - _length

	# a _curve's final point is its end, aka the furthest 'forward', which is why it is p1
	# path_p1 and path_p2 are the curve's start and end respectively
	var path_p1  := _curve.get_closest_offset(_curve.get_point_position(_curve.point_count-1))
	var path_p2  := _curve.get_closest_offset(_curve.get_point_position(0))

	# if at front (or beyond)
	if is_equal_approx(p1, path_p1):
		# if too large
		if p2 < path_p2:
			return -1
	# if too far back
	elif p2 < path_p2:
		# check if snapping will over-extend
		if has_snap_interval():
			# snapping p1_new may move it further back, and out-of-bounds
			# larger snaps move the object further forward
			var p1_new = path_p2 + _length
			var ideal_snap = snappedf(p1_new, snap_interval)
			var more_snap = _snappedf_up(p1_new, snap_interval)
			# if ideal snap fits, take that
			if ideal_snap >= p1_new:
				return ideal_snap
			return more_snap
		return path_p2 + _length
	# otherwise: within bounds
	return p1


## Round 'x' upwards to the nearest 'step'
func _snappedf_up(x, step) -> float:
	return step * ceilf(x / step)


func _find_offset(_path: Path3D, _global_position: Vector3) -> float:
	# transform target pos to local space
	var local_pos: Vector3 = _global_position * _path.global_transform
	return _path.curve.get_closest_offset(local_pos)
