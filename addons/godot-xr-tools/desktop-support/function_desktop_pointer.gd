@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsDesktopFunctionPointer
extends Node3D

## XR Tools Function Pointer Script
##
## This script implements a pointer function for a players controller. Pointer
## events (entered, exited, pressed, release, and movement) are delivered by
## invoking signals on the target node.
##
## Pointer target nodes commonly extend from XRToolsInteractableArea or
## XRToolsInteractableBody.

## Signal emitted when this object points at another object
signal pointing_event(event: XRToolsPointerEvent)


## Enumeration of laser show modes
enum LaserShow {
	HIDE = 0,		## Hide laser
	SHOW = 1,		## Show laser
	COLLIDE = 2,	## Only show laser on collision
}

## Enumeration of laser length modes
enum LaserLength {
	FULL = 0,		## Full length
	COLLIDE = 1,	## Draw to collision
}


## Default pointer collision mask of 21:pointable and 23:ui-objects
const DEFAULT_MASK := 0b0000_0000_0101_0000_0000_0000_0000_0000

## Default pointer collision mask of 23:ui-objects
const SUPPRESS_MASK := 0b0000_0000_0100_0000_0000_0000_0000_0000


@export_group("General")

## Pointer enabled
@export var enabled: bool = true: set = set_enabled

## Y Offset for pointer
@export var y_offset: float = -0.013: set = set_y_offset

## Pointer distance
@export var distance: float = 10: set = set_distance

## Active button action
@export var active_button_action: String = "trigger_click"

@export_group("Laser")

## Controls when the laser is visible
@export var show_laser: LaserShow = LaserShow.SHOW: set = set_show_laser

## Controls the length of the laser
@export var laser_length: LaserLength = LaserLength.FULL: set = set_laser_length

## Laser pointer material
@export var laser_material: StandardMaterial3D = null : set = set_laser_material

## Laser pointer material when hitting target
@export var laser_hit_material: StandardMaterial3D = null : set = set_laser_hit_material

@export_group("Target")

## If true, the pointer target is shown
@export var show_target: bool = false: set = set_show_target

## Controls the target radius
@export var target_radius: float = 0.05: set = set_target_radius

## Target material
@export var target_material: StandardMaterial3D = null : set = set_target_material

@export_group("Collision")

## Pointer collision mask
@export_flags_3d_physics var collision_mask: int = DEFAULT_MASK: set = set_collision_mask

## Enable pointer collision with bodies
@export var collide_with_bodies: bool = true: set = set_collide_with_bodies

## Enable pointer collision with areas
@export var collide_with_areas: bool = false: set = set_collide_with_areas

@export_group("Suppression")

## Suppress radius
@export var suppress_radius: float = 0.2: set = set_suppress_radius

## Suppress mask
@export_flags_3d_physics var suppress_mask: int = SUPPRESS_MASK: set = set_suppress_mask


## Current target node
var target: Node3D = null

## Last target node
var last_target: Node3D = null

## Last collision point
var last_collided_at: Vector3 = Vector3.ZERO

## World scale
var _world_scale: float = 1.0

## XRStart Node
@onready var xr_start_node: Node = XRTools.find_xr_child(
		XRTools.find_xr_ancestor(
				self,
				"*Staging",
				"XRToolsStaging",
		),
		"StartXR",
		"Node",
)

## [MeshInstance3D] child for the laser
@onready var _laser: MeshInstance3D = $Laser

## [RayCast3D] used to find targets
@onready var _raycast: RayCast3D = $RayCast

## [Area3D] used for suppression
@onready var _suppress_area: Area3D = $SuppressArea

## [CollisionShape3D] used for suppression
@onready var _suppress_collider: CollisionShape3D = $SuppressArea/CollisionShape3D

## [MeshInstance3D] child that is displayed at target's position
@onready var _target_mesh: MeshInstance3D = $Target


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Read the initial world-scale
	_world_scale = XRServer.world_scale

	# init our state
	_update_y_offset()
	_update_distance()
	_update_pointer()
	_update_target_radius()
	_update_target_material()
	_update_collision_mask()
	_update_collide_with_bodies()
	_update_collide_with_areas()
	_update_suppress_radius()
	_update_suppress_mask()


# Called on each frame to update the pickup
func _process(_delta: float) -> void:
	# Do not process if in the editor
	if Engine.is_editor_hint() or not is_inside_tree():
		return

	# Handle world-scale changes
	var new_world_scale := XRServer.world_scale

	if _world_scale != new_world_scale:
		_world_scale = new_world_scale
		_update_y_offset()

	set_enabled(not xr_start_node.is_xr_active())

	if Input.is_action_just_released(active_button_action):
		_on_button_pressed(active_button_action)
		await get_tree().process_frame
		_on_button_released(active_button_action)

	# Find the new pointer target
	var new_target: Node3D
	var new_at: Vector3
	var suppress_area := _suppress_area
	if (
			enabled
			and not _suppress_area.has_overlapping_bodies()
			and not _suppress_area.has_overlapping_areas()
			and _raycast.is_colliding()
	):
		new_at = _raycast.get_collision_point()

		if target:
			# Locked to 'target' even if we're colliding with something else
			new_target = target
		else:
			# Target is whatever the raycast is colliding with
			new_target = _raycast.get_collider()

	# If no current or previous collisions then skip
	if not new_target and not last_target:
		return

	# Handle pointer changes
	if new_target and not last_target:
		# Pointer entered new_target
		XRToolsPointerEvent.entered(self, new_target, new_at)

		# Pointer moved on new_target for the first time
		XRToolsPointerEvent.moved(self, new_target, new_at, new_at)

		# Update visible artifacts for hit
		_visible_hit(new_at)
	elif not new_target and last_target:
		# Pointer exited last_target
		XRToolsPointerEvent.exited(self, last_target, last_collided_at)

		# Update visible artifacts for miss
		_visible_miss()
	elif new_target != last_target:
		# Pointer exited last_target
		XRToolsPointerEvent.exited(self, last_target, last_collided_at)

		# Pointer entered new_target
		XRToolsPointerEvent.entered(self, new_target, new_at)

		# Pointer moved on new_target
		XRToolsPointerEvent.moved(self, new_target, new_at, new_at)

		# Move visible artifacts
		_visible_move(new_at)
	elif new_at != last_collided_at:
		# Pointer moved on new_target
		XRToolsPointerEvent.moved(self, new_target, new_at, last_collided_at)

		# Move visible artifacts
		_visible_move(new_at)

	# Update last values
	last_target = new_target
	last_collided_at = new_at


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check the controller node
	if not XRTools.find_xr_ancestor(self, "*", "XRCamera3D"):
		warnings.append("This node must be within a branch of an XRCamera3D node")

	# Return warnings
	return warnings


## Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsDesktopFunctionPointer"


## Set pointer enabled property
func set_enabled(p_enabled: bool) -> void:
	enabled = p_enabled
	if is_inside_tree():
		_update_pointer()


## Set pointer y_offset property
func set_y_offset(p_offset: float) -> void:
	y_offset = p_offset
	if is_inside_tree():
		_update_y_offset()


## Set pointer distance property
func set_distance(p_new_value: float) -> void:
	distance = p_new_value
	if is_inside_tree():
		_update_distance()


## Set pointer show_laser property
func set_show_laser(p_show: LaserShow) -> void:
	show_laser = p_show
	if is_inside_tree():
		_update_pointer()


## Set pointer laser_length property
func set_laser_length(p_laser_length: LaserLength) -> void:
	laser_length = p_laser_length
	if is_inside_tree():
		_update_pointer()


## Set pointer laser_material property
func set_laser_material(p_laser_material: StandardMaterial3D) -> void:
	laser_material = p_laser_material
	if is_inside_tree():
		_update_pointer()


## Set pointer laser_hit_material property
func set_laser_hit_material(p_laser_hit_material: StandardMaterial3D) -> void:
	laser_hit_material = p_laser_hit_material
	if is_inside_tree():
		_update_pointer()


## Set pointer show_target property
func set_show_target(p_show_target: bool) -> void:
	show_target = p_show_target
	if is_inside_tree():
		_target_mesh.visible = enabled and show_target and last_target


## Set pointer target_radius property
func set_target_radius(p_target_radius: float) -> void:
	target_radius = p_target_radius
	if is_inside_tree():
		_update_target_radius()


## Set pointer target_material property
func set_target_material(p_target_material: StandardMaterial3D) -> void:
	target_material = p_target_material
	if is_inside_tree():
		_update_target_material()


## Set pointer collision_mask property
func set_collision_mask(p_new_mask: int) -> void:
	collision_mask = p_new_mask
	if is_inside_tree():
		_update_collision_mask()


## Set pointer collide_with_bodies property
func set_collide_with_bodies(p_new_value: bool) -> void:
	collide_with_bodies = p_new_value
	if is_inside_tree():
		_update_collide_with_bodies()


## Set pointer collide_with_areas property
func set_collide_with_areas(p_new_value: bool) -> void:
	collide_with_areas = p_new_value
	if is_inside_tree():
		_update_collide_with_areas()


## Set suppress radius property
func set_suppress_radius(p_suppress_radius: float) -> void:
	suppress_radius = p_suppress_radius
	if is_inside_tree():
		_update_suppress_radius()


## Set suppress mask property
func set_suppress_mask(p_suppress_mask: int) -> void:
	suppress_mask = p_suppress_mask
	if is_inside_tree():
		_update_suppress_mask()


# Pointer Y offset update handler
func _update_y_offset() -> void:
	_laser.position.y = y_offset * _world_scale
	_raycast.position.y = y_offset * _world_scale


# Pointer distance update handler
func _update_distance() -> void:
	_raycast.target_position.z = -distance
	_update_pointer()


# Pointer target radius update handler
func _update_target_radius() -> void:
	_target_mesh.mesh.radius = target_radius
	_target_mesh.mesh.height = target_radius * 2


# Pointer target_material update handler
func _update_target_material() -> void:
	_target_mesh.set_surface_override_material(0, target_material)


# Pointer collision_mask update handler
func _update_collision_mask() -> void:
	_raycast.collision_mask = collision_mask


# Pointer collide_with_bodies update handler
func _update_collide_with_bodies() -> void:
	_raycast.collide_with_bodies = collide_with_bodies


# Pointer collide_with_areas update handler
func _update_collide_with_areas() -> void:
	_raycast.collide_with_areas = collide_with_areas


# Pointer suppress_radius update handler
func _update_suppress_radius() -> void:
	_suppress_collider.shape.radius = suppress_radius


# Pointer suppress_mask update handler
func _update_suppress_mask() -> void:
	_suppress_area.collision_mask = suppress_mask


# Pointer visible artifacts update handler
func _update_pointer() -> void:
	if enabled and last_target:
		_visible_hit(last_collided_at)
	else:
		_visible_miss()


# Pointer-activation button pressed handler
func _button_pressed() -> void:
	if _raycast.is_colliding():
		# Report pressed
		target = _raycast.get_collider()
		last_collided_at = _raycast.get_collision_point()
		XRToolsPointerEvent.pressed(self, target, last_collided_at)


# Pointer-activation button released handler
func _button_released() -> void:
	if target:
		# Report release
		XRToolsPointerEvent.released(self, target, last_collided_at)
		target = null
		last_collided_at = Vector3(0, 0, 0)


# Button pressed handler
func _on_button_pressed(p_button : String) -> void:
	if p_button == active_button_action and enabled:
		_button_pressed()


# Button released handler
func _on_button_released(p_button : String) -> void:
	if p_button == active_button_action and target:
		_button_released()


# Update the laser active material
func _update_laser_active_material(hit : bool) -> void:
	if hit and laser_hit_material:
		_laser.set_surface_override_material(0, laser_hit_material)
	else:
		_laser.set_surface_override_material(0, laser_material)


# Update the visible artifacts to show a hit
func _visible_hit(at : Vector3) -> void:
	# Show target if enabled
	if show_target:
		_target_mesh.global_transform.origin = at
		_target_mesh.visible = true

	# Control laser visibility
	if show_laser != LaserShow.HIDE:
		# Ensure the correct laser material is set
		_update_laser_active_material(true)

		# Adjust laser length
		if laser_length == LaserLength.COLLIDE:
			var collide_len : float = at.distance_to(global_transform.origin)
			_laser.mesh.size.z = collide_len
			_laser.position.z = collide_len * -0.5
		else:
			_laser.mesh.size.z = distance
			_laser.position.z = distance * -0.5

		# Show laser
		_laser.visible = true
	else:
		# Ensure laser is hidden
		_laser.visible = false


# Move the visible pointer artifacts to the target
func _visible_move(at : Vector3) -> void:
	# Move target if configured
	if show_target:
		_target_mesh.global_transform.origin = at

	# Adjust laser length if set to collide-length
	if laser_length == LaserLength.COLLIDE:
		var collide_len : float = at.distance_to(global_transform.origin)
		_laser.mesh.size.z = collide_len
		_laser.position.z = collide_len * -0.5


# Update the visible artifacts to show a miss
func _visible_miss() -> void:
	# Ensure target is hidden
	_target_mesh.visible = false

	# Ensure the correct laser material is set
	_update_laser_active_material(false)

	# Hide laser if not set to show always
	_laser.visible = show_laser == LaserShow.SHOW

	# Restore laser length if set to collide-length
	_laser.mesh.size.z = distance
	_laser.position.z = distance * -0.5
