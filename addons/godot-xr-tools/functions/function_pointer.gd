tool
class_name XRToolsFunctionPointer, "res://addons/godot-xr-tools/editor/icons/function.svg"
extends Spatial


## XR Tools Function Pointer Script
##
## This script implements a pointer function for a players controller. Pointer
## events (entered, exited, pressed, release, and movement) are delivered by
## invoking signals on the target node.
##
## Pointer target nodes commonly extend from [XRToolsInteractableArea] or
## [XRToolsInteractableBody].


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


# Default pointer collision mask of 21:pointable
const DEFAULT_MASK := 0b0000_0000_0001_0000_0000_0000_0000_0000


## Pointer enabled property
export var enabled : bool = true setget set_enabled

## Show laser property
export (LaserShow) var show_laser : int = LaserShow.SHOW setget set_show_laser

## Laser length property
export (LaserLength) var laser_length : int = LaserLength.FULL

## If true, the pointer target is shown
export var show_target : bool = false

## Y Offset for pointer
export var y_offset : float = -0.05 setget set_y_offset

## Pointer distance
export var distance : float = 10 setget set_distance

## Pointer collision mask
export (int, LAYERS_3D_PHYSICS) var collision_mask : int = DEFAULT_MASK setget set_collision_mask

## Enable pointer collision with bodies
export var collide_with_bodies : bool = true setget set_collide_with_bodies

## Enable pointer collision with areas
export var collide_with_areas : bool = false setget set_collide_with_areas

## Active button
export (XRTools.Buttons) var active_button : int = XRTools.Buttons.VR_TRIGGER

## Action to monitor (if button set to VR_ACTION)
export var action = ""


## Current target node
var target : Spatial

## Last target node
var last_target : Spatial

## Last collision point
var last_collided_at : Vector3 = Vector3.ZERO

# World scale
var _world_scale : float = 1.0

# Left controller node
var _controller_left_node : ARVRController

# Right controller node
var _controller_right_node : ARVRController

# Parent controller (if this pointer is childed to a specific controller)
var _controller  : ARVRController

# The currently active controller
var _active_controller : ARVRController


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsFunctionPointer" or .is_class(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Do not initialise if in the editor
	if Engine.editor_hint:
		return

	# Read the initial world-scale
	_world_scale = ARVRServer.world_scale

	# Check for a parent controller
	_controller = ARVRHelpers.get_arvr_controller(self)
	if _controller:
		# Set as active on the parent controller
		_active_controller = _controller

		# If pointer-trigger is a button then subscribe to button signals
		if active_button != XRTools.Buttons.VR_ACTION:
			# Get button press feedback from controller
			_controller.connect("button_pressed", self, "_on_button_pressed", [_controller])
			_controller.connect("button_release", self, "_on_button_release", [_controller])
	else:
		# Get the left and right controllers
		_controller_left_node = ARVRHelpers.get_left_controller(self)
		_controller_right_node = ARVRHelpers.get_right_controller(self)

		# Start out right hand controller
		_active_controller = _controller_right_node

		# Get button press feedback from both left and right controllers
		_controller_left_node.connect("button_pressed", self, "_on_button_pressed",
										[_controller_left_node])
		_controller_left_node.connect("button_release", self, "_on_button_release",
										[_controller_left_node])
		_controller_right_node.connect("button_pressed", self, "_on_button_pressed",
										[_controller_right_node])
		_controller_right_node.connect("button_release", self, "_on_button_release",
										[_controller_right_node])

	# init our state
	_update_y_offset()
	_update_distance()
	_update_collision_mask()
	_update_show_laser()
	_update_collide_with_bodies()
	_update_collide_with_areas()
	_update_set_enabled()


# Called on each frame to update the pickup
func _process(_delta):
	# Do not process if in the editor
	if Engine.editor_hint or !is_inside_tree():
		return

	# Track the active controller (if this pointer is not childed to a controller)
	if _controller == null and _active_controller != null:
		transform = _active_controller.transform

	# If pointer-trigger is an action then check for action
	if active_button == XRTools.Buttons.VR_ACTION and action != "":
		if Input.is_action_just_pressed(action):
			_button_pressed()
		elif !Input.is_action_pressed(action) and target:
			_button_released()

	# Handle world-scale changes
	var new_world_scale := ARVRServer.world_scale
	if (_world_scale != new_world_scale):
		_world_scale = new_world_scale
		_update_y_offset()

	if enabled and $RayCast.is_colliding():
		var new_at = $RayCast.get_collision_point()

		if is_instance_valid(target):
			# if target is set our mouse must be down, we keep "focus" on our target
			if new_at != last_collided_at:
				if target.has_signal("pointer_moved"):
					target.emit_signal("pointer_moved", last_collided_at, new_at)
				elif target.has_method("pointer_moved"):
					target.pointer_moved(last_collided_at, new_at)
		else:
			var new_target = $RayCast.get_collider()

			# are we pointing to a new target?
			if new_target != last_target:
				# exit the old
				if is_instance_valid(last_target):
					if last_target.has_signal("pointer_exited"):
						last_target.emit_signal("pointer_exited")
					elif last_target.has_method("pointer_exited"):
						last_target.pointer_exited()

				# enter the new
				if is_instance_valid(new_target):
					if new_target.has_signal("pointer_entered"):
						new_target.emit_signal("pointer_entered")
					elif new_target.has_method("pointer_entered"):
						new_target.pointer_entered()

				last_target = new_target

			if new_at != last_collided_at:
				if new_target.has_signal("pointer_moved"):
					new_target.emit_signal("pointer_moved", last_collided_at, new_at)
				elif new_target.has_method("pointer_moved"):
					new_target.pointer_moved(last_collided_at, new_at)

		if last_target:
			# Show target if configured
			if show_target:
				$Target.global_transform.origin = new_at
				$Target.visible = true

			# Show laser if set to show-on-collide
			if show_laser == LaserShow.COLLIDE:
				$Laser.visible = true

			# Adjust laser length if set to collide-length
			if laser_length == LaserLength.COLLIDE:
				var collide_len : float = new_at.distance_to(global_transform.origin)
				$Laser.mesh.size.z = collide_len
				$Laser.translation.z = collide_len * -0.5

		# remember our new position
		last_collided_at = new_at
	else:
		if is_instance_valid(last_target):
			if last_target.has_signal("pointer_exited"):
				last_target.emit_signal("pointer_exited")
			elif last_target.has_method("pointer_exited"):
				last_target.pointer_exited()

		last_target = null

		# Ensure target is hidden
		$Target.visible = false

		# Hide laser if set to show-on-collide
		if show_laser == LaserShow.COLLIDE:
			$Laser.visible = false

		# Restore laser length if set to collide-length
		if laser_length == LaserLength.COLLIDE:
			$Laser.mesh.size.z = distance
			$Laser.translation.z = distance * -0.5


# Set pointer enabled property
func set_enabled(p_enabled : bool) -> void:
	enabled = p_enabled

	# this gets called before our scene is ready, we'll call this again in _ready to enable this
	if is_inside_tree():
		_update_set_enabled()


# Set show-laser property
func set_show_laser(p_show : int) -> void:
	show_laser = p_show
	if is_inside_tree():
		_update_show_laser()


# Set pointer Y offset property
func set_y_offset(p_offset : float) -> void:
	y_offset = p_offset
	if is_inside_tree():
		_update_y_offset()


# Set pointer distance property
func set_distance(p_new_value : float) -> void:
	distance = p_new_value
	if is_inside_tree():
		_update_distance()


# Set pointer collision mask property
func set_collision_mask(p_new_mask : int) -> void:
	collision_mask = p_new_mask
	if is_inside_tree():
		_update_collision_mask()


# Set pointer collide-with-bodies property
func set_collide_with_bodies(p_new_value : bool) -> void:
	collide_with_bodies = p_new_value
	if is_inside_tree():
		_update_collide_with_bodies()


# Set pointer collide-with-areas property
func set_collide_with_areas(p_new_value : bool) -> void:
	collide_with_areas = p_new_value
	if is_inside_tree():
		_update_collide_with_areas()


# Pointer enabled update handler
func _update_set_enabled() -> void:
	$Laser.visible = enabled and show_laser
	$RayCast.enabled = enabled


# Pointer show-laser update handler
func _update_show_laser() -> void:
	$Laser.visible = enabled and show_laser == LaserShow.SHOW


# Pointer Y offset update handler
func _update_y_offset() -> void:
	$Laser.translation.y = y_offset * _world_scale
	$RayCast.translation.y = y_offset * _world_scale


# Pointer distance update handler
func _update_distance() -> void:
	$Laser.mesh.size.z = distance
	$Laser.translation.z = distance * -0.5
	$RayCast.cast_to.z = -distance


# Pointer collision mask update handler
func _update_collision_mask() -> void:
	$RayCast.collision_mask = collision_mask


# Pointer collide-with-bodies update handler
func _update_collide_with_bodies() -> void:
	$RayCast.collide_with_bodies = collide_with_bodies


# Pointer collide-with-areas update handler
func _update_collide_with_areas() -> void:
	$RayCast.collide_with_areas = collide_with_areas


# Pointer-activation button pressed handler
func _button_pressed() -> void:
	if $RayCast.is_colliding():
		target = $RayCast.get_collider()
		last_collided_at = $RayCast.get_collision_point()

		if target.has_signal("pointer_pressed"):
			target.emit_signal("pointer_pressed", last_collided_at)
		elif target.has_method("pointer_pressed"):
			target.pointer_pressed(last_collided_at)


# Pointer-activation button released handler
func _button_released() -> void:
	if target:
		if target.has_signal("pointer_released"):
			target.emit_signal("pointer_released", last_collided_at)
		elif target.has_method("pointer_released"):
			target.pointer_released(last_collided_at)

		# unset target
		target = null
		last_collided_at = Vector3(0, 0, 0)


# Button pressed handler
func _on_button_pressed(p_button : int, controller : ARVRController) -> void:
	if p_button == active_button and enabled:
		if controller == _active_controller:
			_button_pressed()
		else:
			_active_controller = controller


# Button released handler
func _on_button_release(p_button : int, _controller : ARVRController) -> void:
	if p_button == active_button and target:
		_button_released()
