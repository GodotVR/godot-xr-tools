@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsFunctionGazePointer
extends Node3D

## XR Tools Function Gaze Pointer Script
##
## This script implements a pointer function for a players camera. Pointer
## events are delivered by invoking signals on the target node.
##
## Pointer target nodes commonly extend from [XRToolsInteractableArea] or
## [XRToolsInteractableBody].

## Emitted when this object points at another object
signal pointing_event(event: XRToolsPointerEvent)


## Whether to show the laser
enum LaserShow {
	HIDE = 0,		## Hide laser
	SHOW = 1,		## Show laser
	COLLIDE = 2,	## Only show laser on collision
}

## How long the laser should be
enum LaserLength {
	FULL = 0,		## Full length
	COLLIDE = 1		## Draw to collision
}


## Default pointer collision mask of 21:pointable and 23:ui-objects
const DEFAULT_MASK := 0b0000_0000_0101_0000_0000_0000_0000_0000

## Default pointer collision mask of 23:ui-objects
const SUPPRESS_MASK := 0b0000_0000_0100_0000_0000_0000_0000_0000


@export_group("General")

## Whether the pointer is enabled
@export var enabled := true: set = set_enabled

## Y offset of pointer
@export var y_offset := -0.013: set = set_y_offset

## Specifies how far our pointer tests for collisions
@export var distance := 10.0: set = set_distance

## Action in our action map that triggers the pointer action
@export var active_button_action := "trigger_click"

@export_group("Laser")

## When the laser is visible
@export var show_laser := LaserShow.SHOW: set = set_show_laser

## Whether the laser is always full or stops at collision
@export var laser_length := LaserLength.FULL: set = set_laser_length

## Custom material for laser
@export var laser_material: StandardMaterial3D = null : set = set_laser_material

## Custom material for laser upon hit
@export var laser_hit_material: StandardMaterial3D = null : set = set_laser_hit_material

@export_group("Target")

## Whether the hit indicator is shown
@export var show_target := false: set = set_show_target

## Size of hit indicator
@export var target_radius := 0.05: set = set_target_radius

## Custom material of hit indicator
@export var target_material: StandardMaterial3D = null : set = set_target_material

@export_group("Collision")

## Physics layers that laser can collide with
@export_flags_3d_physics var collision_mask := DEFAULT_MASK: set = set_collision_mask

## Whether laser can collide with Physics Bodies
@export var collide_with_bodies := true: set = set_collide_with_bodies

## Whether laser can collide with Physics Areas
@export var collide_with_areas := false: set = set_collide_with_areas

@export_group("Suppression")

## Radius within which we suppress collisions
@export var suppress_radius := 0.2: set = set_suppress_radius

## Physics layers that we suppress within the radius
@export_flags_3d_physics var suppress_mask := SUPPRESS_MASK: set = set_suppress_mask

@export_group("Gaze Pointer")

## Whether to send clicks on hold or just move the mouse
@export var click_on_hold := false

## Time on hold to release a click
@export var hold_time := 2.0

## Color of visualisation
@export var color := Color(1.0, 1.0, 1.0, 1.0): set = set_color

## Size of the pointer's end
@export var size := Vector2(0.3, 0.3): set = set_size

## Whether to release click
var gaze_pressed := false

## Last collision point
var last_collided_at := Vector3.ZERO

## Last target node
var last_target: Node3D = null

## Hold-to-click cursor material
var material: ShaderMaterial

## Current target node
var target: Node3D = null

## How long the player's gaze has been held
var time_held := 0.0

# The current camera
var _camera_parent: XRCamera3D

# World scale
var _world_scale := 1.0

@onready var _laser: MeshInstance3D = $Laser
@onready var _ray: RayCast3D = $RayCast
@onready var _suppress_area: Area3D = $SuppressArea
@onready var _suppress_collider: CollisionShape3D = $SuppressArea/CollisionShape3D
@onready var _target: MeshInstance3D = $Target
@onready var _visualise: MeshInstance3D = $Visualise


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Read the initial world-scale
	_world_scale = XRServer.world_scale

	_camera_parent = get_parent() as XRCamera3D

	material = _visualise.get_surface_override_material(0)

	if not Engine.is_editor_hint():
		_set_time_held(0.0)

	_update_size()
	_update_color()

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
func _process(delta: float) -> void:
	# Do not process if in the editor
	if Engine.is_editor_hint() or not is_inside_tree():
		return

	# Handle world-scale changes
	var new_world_scale := XRServer.world_scale
	if (_world_scale != new_world_scale):
		_world_scale = new_world_scale
		_update_y_offset()

	# Find the new pointer target
	var new_target: Node3D
	var new_at: Vector3
	var suppress_area := _suppress_area
	if (
			enabled
			and not _suppress_area.has_overlapping_bodies()
			and not _suppress_area.has_overlapping_areas()
			and _ray.is_colliding()
	):
		new_at = _ray.get_collision_point()
		if target:
			# Locked to 'target' even if we're colliding with something else
			new_target = target
		else:
			# Target is whatever the raycast is colliding with
			new_target = _ray.get_collider()

	# hide gaze pointer when pressed
	show_target = not gaze_pressed

	# If no current or previous collisions then skip
	if not new_target and not last_target:
		return

	# Handle pointer changes
	if new_target and not last_target:
		# Pointer entered new_target
		XRToolsPointerEvent.entered(self, new_target, new_at)

		# Pointer moved on new_target for the first time
		XRToolsPointerEvent.moved(self, new_target, new_at, new_at)

		if click_on_hold and not gaze_pressed:
			_set_time_held(time_held + delta)
			if time_held > hold_time:
				_button_pressed()

		# Update visible artifacts for hit
		_visible_hit(new_at)
	elif not new_target and last_target:
		# Pointer exited last_target
		XRToolsPointerEvent.exited(self, last_target, last_collided_at)

		if click_on_hold:
			_set_time_held(0.0)
			gaze_pressed = false

		# Update visible artifacts for miss
		_visible_miss()
	elif new_target != last_target:
		# Pointer exited last_target
		XRToolsPointerEvent.exited(self, last_target, last_collided_at)

		if click_on_hold:
			_set_time_held(0.0)
			gaze_pressed = false

		# Pointer entered new_target
		XRToolsPointerEvent.entered(self, new_target, new_at)

		# Pointer moved on new_target
		XRToolsPointerEvent.moved(self, new_target, new_at, new_at)

		if click_on_hold and not gaze_pressed:
			_set_time_held(time_held + delta)
			if time_held > hold_time:
				_button_pressed()

		# Move visible artifacts
		_visible_move(new_at)
	elif new_at != last_collided_at:
		# Pointer moved on new_target
		XRToolsPointerEvent.moved(self, new_target, new_at, last_collided_at)

		if click_on_hold and not gaze_pressed:
			_set_time_held(time_held + delta)
			if time_held > hold_time:
				_button_pressed()

		# Move visible artifacts
		_visible_move(new_at)

	# Update last values
	last_target = new_target
	last_collided_at = new_at


## Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsFunctionGazePointer"


## Toggle whether to collide with areas
func set_collide_with_areas(p_new_value: bool) -> void:
	collide_with_areas = p_new_value
	if is_inside_tree():
		_update_collide_with_areas()


## Toggle whether to collide with bodies
func set_collide_with_bodies(p_new_value: bool) -> void:
	collide_with_bodies = p_new_value
	if is_inside_tree():
		_update_collide_with_bodies()


## Set pointer collision mask
func set_collision_mask(p_new_mask: int) -> void:
	collision_mask = p_new_mask
	if is_inside_tree():
		_update_collision_mask()


## Set color of the gaze pointer
func set_color(p_color: Color) -> void:
	color = p_color
	_update_color()


## Toggle pointer
func set_enabled(p_enabled: bool) -> void:
	enabled = p_enabled
	if is_inside_tree():
		_update_pointer()


## Set the max distance of the pointer
func set_distance(p_new_value: float) -> void:
	distance = p_new_value
	if is_inside_tree():
		_update_distance()


## Set the material of what the laser hits
func set_laser_hit_material(p_laser_hit_material: StandardMaterial3D) -> void:
	laser_hit_material = p_laser_hit_material
	if is_inside_tree():
		_update_pointer()


## Toggle the length of the pointer
func set_laser_length(p_laser_length: LaserLength) -> void:
	laser_length = p_laser_length
	if is_inside_tree():
		_update_pointer()


## Set the material of the laser
func set_laser_material(p_laser_material: StandardMaterial3D) -> void:
	laser_material = p_laser_material
	if is_inside_tree():
		_update_pointer()


## Toggle when to show laser
func set_show_laser(p_show: LaserShow) -> void:
	show_laser = p_show
	if is_inside_tree():
		_update_pointer()


## Toggle showing the laser target
func set_show_target(p_show_target: bool) -> void:
	show_target = p_show_target
	if is_inside_tree():
		_target.visible = enabled and show_target and last_target


## Set size of pointer
func set_size(p_size: Vector2) -> void:
	size = p_size
	_update_size()


## Set radius of pointer target
func set_target_radius(p_target_radius: float) -> void:
	target_radius = p_target_radius
	if is_inside_tree():
		_update_target_radius()


## Set material of pointer target
func set_target_material(p_target_material: StandardMaterial3D) -> void:
	target_material = p_target_material
	if is_inside_tree():
		_update_target_material()


## Set suppress mask
func set_suppress_mask(p_suppress_mask: int) -> void:
	suppress_mask = p_suppress_mask
	if is_inside_tree():
		_update_suppress_mask()


## Set suppress radius
func set_suppress_radius(p_suppress_radius: float) -> void:
	suppress_radius = p_suppress_radius
	if is_inside_tree():
		_update_suppress_radius()


## Set y-offset
func set_y_offset(p_offset: float) -> void:
	y_offset = p_offset
	if is_inside_tree():
		_update_y_offset()


# Sends Pointer Event for button press
func _button_pressed() -> void:
	if _ray.is_colliding():
		# Report pressed
		target = _ray.get_collider()
		last_collided_at = _ray.get_collision_point()
		XRToolsPointerEvent.pressed(self, target, last_collided_at)
		if click_on_hold:
			_set_time_held(0.0)
			gaze_pressed = true
			XRToolsPointerEvent.released(self, last_target, last_collided_at)
			target = null
			_set_time_held(0.0)


# Sends Pointer Event for button release
func _button_released() -> void:
	if target:
		# Report release
		XRToolsPointerEvent.released(self, target, last_collided_at)
		target = null
		last_collided_at = Vector3(0, 0, 0)


# Determines time spent looking at target
func _set_time_held(p_time_held: float) -> void:
	time_held = p_time_held
	if material:
		_visualise.visible = time_held > 0.0
		material.set_shader_parameter("value", time_held / hold_time)


# Toggles Ray Cast's collision with Areas
func _update_collide_with_areas() -> void:
	_ray.collide_with_areas = collide_with_areas


# Toggles Ray Cast's collision with Physics Bodies
func _update_collide_with_bodies() -> void:
	_ray.collide_with_bodies = collide_with_bodies


# Changes physics layers that Ray Cast can collide with
func _update_collision_mask() -> void:
	_ray.collision_mask = collision_mask


# Changes color of pointer
func _update_color() -> void:
	if material:
		material.set_shader_parameter("albedo", color)


# Changes Ray Cast's target distance
func _update_distance() -> void:
	_ray.target_position.z = -distance
	_update_pointer()


# Changes laser material depending on hit
func _update_laser_active_material(hit: bool) -> void:
	if hit and laser_hit_material:
		_laser.set_surface_override_material(0, laser_hit_material)
	else:
		_laser.set_surface_override_material(0, laser_material)


# Changes pointer's visuals depending on hit
func _update_pointer() -> void:
	if enabled and last_target:
		_visible_hit(last_collided_at)
	else:
		_visible_miss()


# Changes gaze pointer size
func _update_size() -> void:
	if material: # Note, material won't be set until after we setup our scene
		var mesh: QuadMesh = _visualise.mesh
		if mesh.size != size:
			mesh.size = size

			# Updating the size will unset our material, so reset it
			_visualise.set_surface_override_material(0, material)


# Changes physics layers suppressed within the radius
func _update_suppress_mask() -> void:
	_suppress_area.collision_mask = suppress_mask


# Changes radius within which we suppress collisions
func _update_suppress_radius() -> void:
	_suppress_collider.shape.radius = suppress_radius


# Changes material for visuals of laser upon hit
func _update_target_material() -> void:
	_target.set_surface_override_material(0, target_material)


# Changes size of hit indicator
func _update_target_radius() -> void:
	_target.mesh.radius = target_radius
	_target.mesh.height = target_radius * 2


# Changes Y offset of laser
func _update_y_offset() -> void:
	_laser.position.y = y_offset * _world_scale
	_ray.position.y = y_offset * _world_scale


# Changes laser to show hit
func _visible_hit(at: Vector3) -> void:
	# Show target if enabled
	if show_target:
		_target.global_transform.origin = at
		_target.visible = true

	# Control laser visibility
	if show_laser != LaserShow.HIDE:
		# Ensure the correct laser material is set
		_update_laser_active_material(true)

		# Adjust laser length
		if laser_length == LaserLength.COLLIDE:
			var collide_len: float = at.distance_to(global_transform.origin)
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


# Changes laser to show miss
func _visible_miss() -> void:
	# Ensure target is hidden
	_target.visible = false

	# Ensure the correct laser material is set
	_update_laser_active_material(false)

	# Hide laser if not set to show always
	_laser.visible = show_laser == LaserShow.SHOW

	# Restore laser length if set to collide-length
	_laser.mesh.size.z = distance
	_laser.position.z = distance * -0.5


# Changes laser to move with Ray Cast
func _visible_move(at: Vector3) -> void:
	# Move target if configured
	if show_target:
		_target.global_transform.origin = at

	# Adjust laser length if set to collide-length
	if laser_length == LaserLength.COLLIDE:
		var collide_len: float = at.distance_to(global_transform.origin)
		_laser.mesh.size.z = collide_len
		_laser.position.z = collide_len * -0.5

	_visualise.global_transform.origin = at
