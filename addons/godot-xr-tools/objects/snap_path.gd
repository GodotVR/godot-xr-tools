@tool
extends XRToolsSnapZone
class_name XRToolsSnapPath

## An [XRToolsSnapZone] that allows [XRToolsPickable] to be placed along a child [Path3D] node.
##     They can either be placed along any point in the curve, or at discrete intervals
##     by setting "snap_interval" above 0.0. Note: Attached [XRToolsPickable]s will face the +Z axis
##
## TODO:
##     Feature: Preview Material that shows the held object on the rail
##     Option: Blocking overlapping [XRToolsPickable] collisions
##     Option: Discrete intervals by subdivision, not real space (Ex: 4 points equally spaced)


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


func _get_configuration_warnings() -> PackedStringArray:
	# Check for Path3D child
	for c in get_children():
		if c is Path3D:
			path = c
			return[]
	return["This node has no path to place objects along. Consider adding a Path3D as a child to define its shape."]


# Called when a target in our grab area is dropped
func _on_target_dropped(target: Node3D) -> void:
	# Skip if invalid
	if !enabled or is_instance_valid(picked_up_object) or !is_instance_valid(target) or !path:
		return
	
	# Make a zone that will destruct once its object has left
	var zone = _make_temp_zone()
	
	# Set zone's transform to respect the rail
	# If snap_interval has been set, use it
	if snap_interval != 0.0:
		var ideal_offset = _find_offset(path, target.global_position)
		var s = snappedf(ideal_offset, snap_interval)
		zone.transform = path.curve.sample_baked_with_rotation(s)
	else:
		zone.transform = path.curve.sample_baked_with_rotation(clamp(_find_offset(path, target.global_position), 0.0, 1.0))
	
	# Add zone as a child
	path.add_child(zone)
	zone.owner = path
	
	# Connect self-destruct with lambda
	zone.has_dropped.connect(func(): zone.queue_free(), Object.ConnectFlags.CONNECT_ONE_SHOT)
	
	# Force pickup
	if target.can_pick_up(self):
		zone.pick_up_object(target)
	else:
		zone.queue_free()


# Make a zone that dies on dropping objects
func _make_temp_zone():
	var zone = preload("res://addons/godot-xr-tools/objects/snap_zone.tscn").instantiate()
	
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


func _find_closest_point(_path: Path3D, _global_position: Vector3) -> Vector3:
	# Transform target pos to local space
	var local_position := global_position * _path.global_transform
	return _path.curve.get_closest_point(local_position)


func _find_offset(_path: Path3D, _global_position: Vector3) -> float:
	# Transform target pos to local space
	var local_pos: Vector3 = _global_position * _path.global_transform
	return _path.curve.get_closest_offset(local_pos)
