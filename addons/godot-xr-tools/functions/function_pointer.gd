@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsFunctionPointer
extends XRToolsHandAimOffset

## XR Tools Function Pointer Script
##
## This script implements a pointer function for a players controller. Pointer
## events are delivered by invoking signals on the target node.
##
## Pointer target nodes commonly extend from [XRToolsInteractableArea] or
## [XRToolsInteractableBody].


## Emitted when this object points at another object
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
	COLLIDE = 1		## Draw to collision
}


## Default pointer collision mask of 21:pointable and 23:ui-objects
const DEFAULT_MASK := 0b0000_0000_0101_0000_0000_0000_0000_0000

## Default pointer collision mask of 23:ui-objects
const SUPPRESS_MASK := 0b0000_0000_0100_0000_0000_0000_0000_0000


@export_group("General")

## Whether the pointer is enabled
@export var enabled := true: set = set_enabled

## Y-offset for pointer
@export var y_offset := -0.013: set = set_y_offset

## How far the pointer checks for collisions
@export var distance := 10.0: set = set_distance

## Action that triggers a [XRToolsPointerEvent] at an object being pointed at
@export var active_button_action := "trigger_click"

@export_group("Laser")

## When the laser is visible
@export var show_laser := LaserShow.SHOW: set = set_show_laser

## Length of the laser
@export var laser_length := LaserLength.FULL: set = set_laser_length

## Laser pointer material
@export var laser_material: StandardMaterial3D = null : set = set_laser_material

## Laser pointer material when hitting target
@export var laser_hit_material: StandardMaterial3D = null : set = set_laser_hit_material

@export_group("Target")

## Whether the hit indicator is shown
@export var show_target := false: set = set_show_target

## Radius of the hit indicator
@export var target_radius := 0.05: set = set_target_radius

## Material of the hit indicator
@export var target_material: StandardMaterial3D = null : set = set_target_material

@export_group("Collision")

## Physics layers that the laser can collide with
@export_flags_3d_physics var collision_mask := DEFAULT_MASK: set = set_collision_mask

## Whether the pointer can collide with Physics Bodies
@export var collide_with_bodies := true: set = set_collide_with_bodies

## Whether the pointer can collide with Areas
@export var collide_with_areas := false: set = set_collide_with_areas

@export_group("Suppression")

## Radius within which we suppress collisions
@export var suppress_radius := 0.2: set = set_suppress_radius

## Physics layers that we suppress within the radius
@export_flags_3d_physics var suppress_mask := SUPPRESS_MASK: set = set_suppress_mask


## Current target node
var target: Node3D = null

## Last target node
var last_target: Node3D = null

## Last collision point
var last_collided_at := Vector3.ZERO

# World scale
var _world_scale := 1.0

# Left controller node
var _controller_left_node: XRController3D

# Right controller node
var _controller_right_node: XRController3D

# Currently active controller
var _active_controller: XRController3D

@onready var _laser: MeshInstance3D = $Laser
@onready var _ray: RayCast3D = $RayCast
@onready var _suppress_area: Area3D = $SuppressArea
@onready var _suppress_collider: CollisionShape3D = $SuppressArea/CollisionShape3D
@onready var _target: MeshInstance3D = $Target


# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	super._enter_tree()

	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Read the initial world-scale
	_world_scale = XRServer.world_scale

	# Check for a parent controller
	if _controller:
		# Set as active on the parent controller
		_active_controller = _controller

		# Get button press feedback from our parent controller
		_controller.button_pressed.connect(_on_button_pressed.bind(_controller))
		_controller.button_released.connect(_on_button_released.bind(_controller))
	else:
		# Disable this if we don't have a controller
		hand_offset_mode = 4

		# Get the left and right controllers
		_controller_left_node = XRHelpers.get_left_controller(self)
		_controller_right_node = XRHelpers.get_right_controller(self)

		# Start out right hand controller
		_active_controller = _controller_right_node

		# Get button press feedback from both left and right controllers
		_controller_left_node.button_pressed.connect(
				_on_button_pressed.bind(_controller_left_node)
		)
		_controller_left_node.button_released.connect(
				_on_button_released.bind(_controller_left_node)
		)
		_controller_right_node.button_pressed.connect(
				_on_button_pressed.bind(_controller_right_node)
		)
		_controller_right_node.button_released.connect(
				_on_button_released.bind(_controller_right_node)
		)

	# init our state
	await get_tree().process_frame
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
	super._process(delta)

	# Do not process if in the editor
	if Engine.is_editor_hint() or not is_inside_tree():
		return

	# Track the active controller (if this pointer is not childed to a controller)
	if _controller == null and _active_controller != null:
		transform = _active_controller.transform

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


func _exit_tree() -> void:
	_active_controller = null

	if _controller and not Engine.is_editor_hint():
		_controller.button_pressed.disconnect(_on_button_pressed.bind(_controller))
		_controller.button_released.disconnect(_on_button_released.bind(_controller))

		# This will be unset in our superclass method

	if _controller_left_node:
		if not Engine.is_editor_hint():
			_controller_left_node.button_pressed.disconnect(
					_on_button_pressed.bind(_controller_left_node))
			_controller_left_node.button_released.disconnect(
					_on_button_released.bind(_controller_left_node))

		_controller_left_node = null

	if _controller_right_node:
		if not Engine.is_editor_hint():
			_controller_right_node.button_pressed.disconnect(
					_on_button_pressed.bind(_controller_right_node))
			_controller_right_node.button_released.disconnect(
					_on_button_released.bind(_controller_right_node))

		_controller_right_node = null

	super._exit_tree()


## Adds support for is_xr_class on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsFunctionPointer"


## Updates whether the pointer can collide with Areas
func set_collide_with_areas(p_new_value: bool) -> void:
	collide_with_areas = p_new_value
	if is_inside_tree():
		_update_collide_with_areas()


## Updates whether the pointer can collide with Physics Bodies
func set_collide_with_bodies(p_new_value: bool) -> void:
	collide_with_bodies = p_new_value
	if is_inside_tree():
		_update_collide_with_bodies()


## Sets the physics layers within which the pointer can collide with objects
func set_collision_mask(p_new_mask: int) -> void:
	collision_mask = p_new_mask
	if is_inside_tree():
		_update_collision_mask()


## Sets how far the pointer can check for collisions
func set_distance(p_new_value: float) -> void:
	distance = p_new_value
	if is_inside_tree():
		_update_distance()


## Sets whether the pointer is enabled
func set_enabled(p_enabled: bool) -> void:
	enabled = p_enabled
	if is_inside_tree():
		_update_pointer()


## Sets the material of the laser when hitting an object
func set_laser_hit_material(p_laser_hit_material: StandardMaterial3D) -> void:
	laser_hit_material = p_laser_hit_material
	if is_inside_tree():
		_update_pointer()


## Sets the length of the laser
func set_laser_length(p_laser_length: LaserLength) -> void:
	laser_length = p_laser_length
	if is_inside_tree():
		_update_pointer()


## Sets the material of the laser
func set_laser_material(p_laser_material: StandardMaterial3D) -> void:
	laser_material = p_laser_material
	if is_inside_tree():
		_update_pointer()


## Sets when the laser should show
func set_show_laser(p_show: LaserShow) -> void:
	show_laser = p_show
	if is_inside_tree():
		_update_pointer()


## Sets whether the hit indicator should show
func set_show_target(p_show_target: bool) -> void:
	show_target = p_show_target
	if is_inside_tree():
		_target.visible = enabled and show_target and last_target


## Sets the physics layers in which we should suppress collisions
func set_suppress_mask(p_suppress_mask: int) -> void:
	suppress_mask = p_suppress_mask
	if is_inside_tree():
		_update_suppress_mask()


## Sets the radius in which we should suppress collisions
func set_suppress_radius(p_suppress_radius: float) -> void:
	suppress_radius = p_suppress_radius
	if is_inside_tree():
		_update_suppress_radius()


## Sets the material of the hit indicator
func set_target_material(p_target_material: StandardMaterial3D) -> void:
	target_material = p_target_material
	if is_inside_tree():
		_update_target_material()


## Sets the radius of the hit indicator
func set_target_radius(p_target_radius: float) -> void:
	target_radius = p_target_radius
	if is_inside_tree():
		_update_target_radius()


## Sets the y-offset of the pointer
func set_y_offset(p_offset: float) -> void:
	y_offset = p_offset
	if is_inside_tree():
		_update_y_offset()


# Sends a pressed XRToolsPointerEvent to an object we're pointing at
func _button_pressed() -> void:
	if _ray.is_colliding():
		# Report pressed
		target = _ray.get_collider()
		last_collided_at = _ray.get_collision_point()
		XRToolsPointerEvent.pressed(self, target, last_collided_at)


# Sends a released XRToolsPointerEvent to an object we're pointing at
func _button_released() -> void:
	if target:
		# Report release
		XRToolsPointerEvent.released(self, target, last_collided_at)
		target = null
		last_collided_at = Vector3(0, 0, 0)


# When a button of an XR Controller is pressed
func _on_button_pressed(p_button: String, controller: XRController3D) -> void:
	if p_button == active_button_action and enabled:
		if controller == _active_controller:
			_button_pressed()
		else:
			_active_controller = controller


# When a button of an XR Controller is released
func _on_button_released(p_button: String, _controller: XRController3D) -> void:
	if p_button == active_button_action and target:
		_button_released()


# Sets whether the Ray Cast can collide with Areas
func _update_collide_with_areas() -> void:
	_ray.collide_with_areas = collide_with_areas


# Sets whether the Ray Cast can collide with Physics Bodies
func _update_collide_with_bodies() -> void:
	_ray.collide_with_bodies = collide_with_bodies


# Sets the physics layers the Ray Cast can collide with
func _update_collision_mask() -> void:
	_ray.collision_mask = collision_mask


# Sets the target position of the Ray Cast
func _update_distance() -> void:
	_ray.target_position.z = -distance
	_update_pointer()


# Sets the laser's current material
func _update_laser_active_material(hit: bool) -> void:
	if hit and laser_hit_material:
		_laser.set_surface_override_material(0, laser_hit_material)
	else:
		_laser.set_surface_override_material(0, laser_material)


# Changes the visuals of the pointer
func _update_pointer() -> void:
	if enabled and last_target:
		_visible_hit(last_collided_at)
	else:
		_visible_miss()


# Sets the physics layers in which we suppress collisions within the radius
func _update_suppress_mask() -> void:
	_suppress_area.collision_mask = suppress_mask


# Sets the radius in which we suppress collisions
func _update_suppress_radius() -> void:
	_suppress_collider.shape.radius = suppress_radius


# Sets the material of the hit indicator
func _update_target_material() -> void:
	_target.set_surface_override_material(0, target_material)


# Sets the radius of the hit indicator
func _update_target_radius() -> void:
	_target.mesh.radius = target_radius
	_target.mesh.height = target_radius * 2


# Sets the y-offset of the laser and Ray Cast
func _update_y_offset() -> void:
	_laser.position.y = y_offset * _world_scale
	_ray.position.y = y_offset * _world_scale


# Changes the visuals to show a hit
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


# Changes the visuals to show a miss
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


# Change the visuals if we hit a target and then move
func _visible_move(at: Vector3) -> void:
	# Move target if configured
	if show_target:
		_target.global_transform.origin = at

	# Adjust laser length if set to collide-length
	if laser_length == LaserLength.COLLIDE:
		var collide_len: float = at.distance_to(global_transform.origin)
		_laser.mesh.size.z = collide_len
		_laser.position.z = collide_len * -0.5
