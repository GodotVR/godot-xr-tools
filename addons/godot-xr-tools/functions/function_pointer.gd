tool
class_name XRToolsFunctionPointer, "res://addons/godot-xr-tools/editor/icons/function.svg"
extends Spatial


##
## Pointer Function Script
##
## @desc:
##     This script implements a pointer function for a players controller. The
##     pointer supports sending signals to XRToolsInteractableArea or
##     XRToolsInteractableBody objects.
##
##     The following signals are sent to these objects:
##      - pointer_pressed(at) with the pointer location
##      - pointer_released(at) with the pointer location
##      - pointer_moved(from, to) with the pointer movement
##      - pointer_entered()
##      - pointer_exited()
##


# enum our buttons, should find a way to put this more central
enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15,
	VR_ACTION = 255
}


## Pointer enabled property
export var enabled : bool = true setget set_enabled

## Show laser property
export var show_laser : bool = true setget set_show_laser

## Show laser target
export var show_target : bool = false

## Y Offset for pointer
export var y_offset : float = -0.05 setget set_y_offset

## Pointer distance
export var distance : float = 10 setget set_distance

## Pointer collision mask
export (int, LAYERS_3D_PHYSICS) var collision_mask : int = 15 setget set_collision_mask

## Enable pointer collision with bodies
export var collide_with_bodies : bool = true setget set_collide_with_bodies

## Enable pointer collision with areas
export var collide_with_areas : bool = false setget set_collide_with_areas

## Active button
export (Buttons) var active_button : int = Buttons.VR_TRIGGER

## Action to monitor (if button set to VR_ACTION)
export var action = ""


# Current target
var target : Spatial

# Last target
var last_target : Spatial

# Last collision point
var last_collided_at : Vector3 = Vector3.ZERO

# World scale
var ws : float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	# Do not initialise if in the editor
	if Engine.editor_hint:
		return

	# Read the initial world-scale
	ws = ARVRServer.world_scale

	# If pointer-trigger is a button then subscribe to button signals
	if active_button != Buttons.VR_ACTION:
		# Get button press feedback from our parent (should be an ARVRController)
		get_parent().connect("button_pressed", self, "_on_button_pressed")
		get_parent().connect("button_release", self, "_on_button_release")

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

	# If pointer-trigger is an action then check for action
	if active_button == Buttons.VR_ACTION and action != "":
		if Input.is_action_just_pressed(action):
			_button_pressed()
		elif !Input.is_action_pressed(action) and target:
			_button_released()

	# Handle world-scale changes
	var new_ws := ARVRServer.world_scale
	if (ws != new_ws):
		ws = new_ws
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

		if last_target and show_target:
			$Target.global_transform.origin = last_collided_at
			$Target.visible = true

		# remember our new position
		last_collided_at = new_at
	else:
		if is_instance_valid(last_target):
			if last_target.has_signal("pointer_exited"):
				last_target.emit_signal("pointer_exited")
			elif last_target.has_method("pointer_exited"):
				last_target.pointer_exited()

		last_target = null
		$Target.visible = false


# Set pointer enabled property
func set_enabled(p_enabled : bool) -> void:
	enabled = p_enabled

	# this gets called before our scene is ready, we'll call this again in _ready to enable this
	if is_inside_tree():
		_update_set_enabled()


# Set show-laser property
func set_show_laser(p_show : bool) -> void:
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
	$Laser.visible = enabled and show_laser


# Pointer Y offset update handler
func _update_y_offset() -> void:
	$Laser.translation.y = y_offset * ws
	$RayCast.translation.y = y_offset * ws


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
func _on_button_pressed(p_button : int) -> void:
	if p_button == active_button and enabled:
		_button_pressed()


# Button released handler
func _on_button_release(p_button : int) -> void:
	if p_button == active_button and target:
		_button_released()
