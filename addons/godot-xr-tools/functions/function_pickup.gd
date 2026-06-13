@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsFunctionPickup
extends XRToolsHandPalmOffset

## XR Tools Function Pickup Script
##
## This script implements picking up of objects. Most pickable
## objects are instances of the [XRToolsPickable] class.
##
## Additionally this script can work in conjunction with the
## [XRToolsMovementProvider] class support climbing. Most climbable objects are
## instances of the [XRToolsClimbable] class.


## Emitted when the pickup picks something up
signal has_picked_up(what: Node3D)

## Emitted when the pickup drops something
signal has_dropped


## Default pickup collision mask of 3:pickable and 19:handle
const DEFAULT_GRAB_MASK := 0b0000_0000_0000_0100_0000_0000_0000_0100

## Default pickup collision mask of 3:pickable
const DEFAULT_RANGE_MASK := 0b0000_0000_0000_0000_0000_0000_0000_0100

## Worst-case grab distance
const MAX_GRAB_DISTANCE2 := 1000000.0

## Whether pickup is enabled
@export var enabled := true

## Action that picks up a Pickable
@export var pickup_axis_action := "grip"

## Action that activates a held Pickable's controller action
@export var action_button_action := "trigger_click"

## Distance at which Pickables can be picked up
@export var grab_distance := 0.3: set = _set_grab_distance

## Physics layers that Pickables must be in to be picked up
@export_flags_3d_physics \
		var grab_collision_mask := DEFAULT_GRAB_MASK: set = _set_grab_collision_mask

## Whether Pickables can be grabbed from afar
@export var ranged_enable := true

## Distance at which Pickables can be grabbed from afar
@export var ranged_distance := 5.0: set = _set_ranged_distance

## Angle at which Pickables can be grabbed from afar
@export_range(0.0, 45.0) var ranged_angle := 5.0: set = _set_ranged_angle

## Physics layers that Pickables must be in to be picked up from afar
@export_flags_3d_physics \
		var ranged_collision_mask := DEFAULT_RANGE_MASK: set = _set_ranged_collision_mask

## Magnitude of impulse to throw held Pickables upon letting go
@export var impulse_factor := 1.0

## How many velocities to use and average out when calculating a throw
@export var velocity_samples: int = 5


## Closest Pickable
var closest_object: Node3D = null
## Currently held Pickable
var picked_up_object: Node3D = null
## Whether a Pickable is in the grab area when the pickup_axis_action has been pressed
var picked_up_ranged := false
## Whether the pickup_axis_action has been pressed
var grip_pressed := false

# Pickables that can be picked up close by
var _object_in_grab_area: Array[Node3D]
# Pickables that can be picked up from afar
var _object_in_ranged_area: Array[Node3D]
# Averages out the velocity of a throw
var _velocity_averager := XRToolsVelocityAverager.new(velocity_samples)
# Area that detects a nearby Pickable to be held
var _grab_area: Area3D
# Collision shape of the above Area
var _grab_collision: CollisionShape3D
# Area that detects a far-away Pickable to be held
var _ranged_area: Area3D
# Collision shape of the above Area
var _ranged_collision: CollisionShape3D
# Collection of collision shapes copied from Pickables
var _active_copied_collisions: Array[CopiedCollision]

## Collision hand (if applicable)
@onready var _collision_hand: XRToolsCollisionHand

## Grip threshold (from configuration)
@onready var _grip_threshold := XRTools.get_grip_threshold()


## Find an [XRToolsFunctionPickup] node.
##
## This function searches from the specified node for an [XRToolsFunctionPickup]
## assuming the node is a sibling of the pickup under an [XRController3D].
static func find_instance(node: Node) -> XRToolsFunctionPickup:
	return XRTools.find_xr_child(
			XRHelpers.get_xr_controller(node),
			"*",
			"XRToolsFunctionPickup",
	) as XRToolsFunctionPickup


## Find the left [XRToolsFunctionPickup] node.
##
## This function searches from the specified node for the left controller
## [XRToolsFunctionPickup] assuming the node is a sibling of the [XOrigin3D].
static func find_left(node: Node) -> XRToolsFunctionPickup:
	return XRTools.find_xr_child(
			XRHelpers.get_left_controller(node),
			"*",
			"XRToolsFunctionPickup",
	) as XRToolsFunctionPickup


## Find the right [XRToolsFunctionPickup] node.
##
## This function searches from the specified node for the right controller
## [XRToolsFunctionPickup] assuming the node is a sibling of the [XROrigin3D].
static func find_right(node: Node) -> XRToolsFunctionPickup:
	return XRTools.find_xr_child(
			XRHelpers.get_right_controller(node),
			"*",
			"XRToolsFunctionPickup",
	) as XRToolsFunctionPickup


# Called when we're added to the tree
func _enter_tree() -> void:
	super._enter_tree()

	_collision_hand = XRToolsCollisionHand.find_ancestor(self)

	# Monitor Grab Button
	if _controller:
		_controller.button_pressed.connect(_on_button_pressed)
		_controller.button_released.connect(_on_button_released)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Skip creating grab-helpers if in the editor
	if Engine.is_editor_hint():
		return

	# Create the grab collision shape
	_grab_collision = CollisionShape3D.new()
	_grab_collision.set_name("GrabCollisionShape")
	_grab_collision.shape = SphereShape3D.new()
	_grab_collision.shape.radius = grab_distance

	# Create the grab area
	_grab_area = Area3D.new()
	_grab_area.set_name("GrabArea")
	_grab_area.collision_layer = 0
	_grab_area.collision_mask = grab_collision_mask
	_grab_area.add_child(_grab_collision)
	_grab_area.area_entered.connect(_on_grab_entered)
	_grab_area.body_entered.connect(_on_grab_entered)
	_grab_area.area_exited.connect(_on_grab_exited)
	_grab_area.body_exited.connect(_on_grab_exited)
	add_child(_grab_area)

	# Create the ranged collision shape
	_ranged_collision = CollisionShape3D.new()
	_ranged_collision.set_name("RangedCollisionShape")
	_ranged_collision.shape = CylinderShape3D.new()
	_ranged_collision.transform.basis = Basis(Vector3.RIGHT, PI/2)

	# Create the ranged area
	_ranged_area = Area3D.new()
	_ranged_area.set_name("RangedArea")
	_ranged_area.collision_layer = 0
	_ranged_area.collision_mask = ranged_collision_mask
	_ranged_area.add_child(_ranged_collision)
	_ranged_area.area_entered.connect(_on_ranged_entered)
	_ranged_area.body_entered.connect(_on_ranged_entered)
	_ranged_area.area_exited.connect(_on_ranged_exited)
	_ranged_area.body_exited.connect(_on_ranged_exited)
	add_child(_ranged_area)

	# Update the colliders
	_update_colliders()


# Called on each frame to update the pickup
func _process(delta: float) -> void:
	super._process(delta)

	# Do not process if in the editor
	if Engine.is_editor_hint():
		return

	# Skip if disabled, or the controller isn't active
	if not enabled or not _controller.get_is_active():
		return

	# Handle our grip
	var grip_value := _controller.get_float(pickup_axis_action)
	if (grip_pressed and grip_value < (_grip_threshold - 0.1)):
		grip_pressed = false
		_on_grip_release()
	elif (not grip_pressed and grip_value > (_grip_threshold + 0.1)):
		grip_pressed = true
		_on_grip_pressed()

	# Calculate average velocity
	if is_instance_valid(picked_up_object) and picked_up_object.is_picked_up():
		# Average velocity of picked up object
		_velocity_averager.add_transform(delta, picked_up_object.global_transform)
	else:
		# Average velocity of this pickup
		_velocity_averager.add_transform(delta, global_transform)

	_update_copied_collisions()
	_update_closest_object()


# Called when we exit the tree
func _exit_tree() -> void:
	if _controller:
		_controller.button_pressed.disconnect(_on_button_pressed)
		_controller.button_released.disconnect(_on_button_released)

	if _collision_hand:
		_remove_copied_collisions()
		_collision_hand = null

	super._exit_tree()


## Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsFunctionPickup"


## Drop the currently held object
func drop_object() -> void:
	if not is_instance_valid(picked_up_object):
		return

	# Remove any copied collision objects
	_remove_copied_collisions()

	# let go of this object
	picked_up_object.let_go(
			self,
			_velocity_averager.linear_velocity() * impulse_factor,
			_velocity_averager.angular_velocity(),
	)
	picked_up_object = null

	if _collision_hand:
		# Reset the held weight
		_collision_hand.set_held_weight(0.0)

	has_dropped.emit()


## Get the [XRController3D] driving this pickup.
func get_controller() -> XRController3D:
	return _controller


# Copy collision shapes on the held object to our collision hand (if applicable).
# If we're two handing an object, both collision hands will get copies.
func _copy_collisions() -> void:
	if not is_instance_valid(_collision_hand):
		return

	if not is_instance_valid(picked_up_object) or not picked_up_object is RigidBody3D:
		return

	for child: Node in picked_up_object.get_children():
		if child is CollisionShape3D and not child.disabled:

			var copied_collision := CopiedCollision.new()
			copied_collision.collision_shape = CollisionShape3D.new()
			copied_collision.collision_shape.shape = child.shape
			copied_collision.org_transform = child.transform

			_collision_hand.add_child(
					copied_collision.collision_shape,
					false,
					Node.INTERNAL_MODE_BACK
			)
			copied_collision.collision_shape.global_transform = picked_up_object.global_transform * \
				copied_collision.org_transform

			_active_copied_collisions.push_back(copied_collision)


# Find the pickable object closest to our hand's grab location
func _get_closest_grab() -> Node3D:
	var new_closest_obj: Node3D = null
	var new_closest_distance := MAX_GRAB_DISTANCE2
	for o: Node3D in _object_in_grab_area:
		# skip objects that can not be picked up
		if not o.can_pick_up(self):
			continue

		# Save if this object is closer than the current best
		var distance_squared := global_transform.origin.distance_squared_to(
				o.global_transform.origin
		)

		if distance_squared < new_closest_distance:
			new_closest_obj = o
			new_closest_distance = distance_squared

	# Return best object
	return new_closest_obj


# Find the rangedly-pickable object closest to our hand's pointing direction
func _get_closest_ranged() -> Node3D:
	var new_closest_obj: Node3D = null
	var new_closest_angle_dp := cos(deg_to_rad(ranged_angle))
	var hand_forwards := -global_transform.basis.z
	for o: Node3D in _object_in_ranged_area:
		# skip objects that can not be picked up
		if not o.can_pick_up(self):
			continue

		# Save if this object is closer than the current best
		var object_direction: Vector3 = o.global_transform.origin - global_transform.origin
		object_direction = object_direction.normalized()

		var angle_dp := hand_forwards.dot(object_direction)

		if angle_dp > new_closest_angle_dp:
			new_closest_obj = o
			new_closest_angle_dp = angle_dp

	# Return best object
	return new_closest_obj


# When a button of an XR Controller is pressed
func _on_button_pressed(p_button: String) -> void:
	if p_button == action_button_action and is_instance_valid(picked_up_object):
		if picked_up_object.has_method("action"):
			picked_up_object.action()

		if picked_up_object.has_method("controller_action"):
			picked_up_object.controller_action(_controller)


# When a button of an XR Controller is released
func _on_button_released(p_button: String) -> void:
	if p_button == action_button_action and is_instance_valid(picked_up_object):
		if picked_up_object.has_method("action_release"):
			picked_up_object.action_release()

		if picked_up_object.has_method("controller_action_release"):
			picked_up_object.controller_action_release(_controller)


# When the grip button of an XR Controller is pressed
func _on_grip_pressed() -> void:
	if is_instance_valid(picked_up_object) and not picked_up_object.press_to_hold:
		drop_object()
	elif is_instance_valid(closest_object):
		_pick_up_object(closest_object)


# When the grip button of an XR Controller is released
func _on_grip_release() -> void:
	if is_instance_valid(picked_up_object) and picked_up_object.press_to_hold:
		drop_object()


# When an object enters the grab sphere
func _on_grab_entered(target: Node3D) -> void:
	# reject objects which don't support picking up
	if not target.has_method('pick_up'):
		return

	# ignore objects already known
	if _object_in_grab_area.find(target) >= 0:
		return

	# Add to the list of objects in grab area
	_object_in_grab_area.push_back(target)


# When an object exits the grab sphere
func _on_grab_exited(target: Node3D) -> void:
	_object_in_grab_area.erase(target)


# When an object enters the ranged-grab cylinder
func _on_ranged_entered(target: Node3D) -> void:
	# reject objects which don't support picking up rangedly
	if not target.has_method('can_ranged_grab') or not target.can_ranged_grab:
		return

	# ignore objects already known
	if _object_in_ranged_area.find(target) >= 0:
		return

	# Add to the list of objects in grab area
	_object_in_ranged_area.push_back(target)


# When an object exits the ranged-grab cylinder
func _on_ranged_exited(target: Node3D) -> void:
	_object_in_ranged_area.erase(target)


# When an object should be picked up
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

	# Handle snap-zone
	var snap := target as XRToolsSnapZone
	if snap:
		target = snap.picked_up_object
		snap.drop_object()

	# Pick up our target. Note, target may do instant drop_and_free
	picked_up_ranged = not _object_in_grab_area.has(target)
	picked_up_object = target
	target.pick_up(self)

	# If object picked up then emit signal
	if is_instance_valid(picked_up_object):
		_copy_collisions()

		picked_up_object.request_highlight(self, false)
		has_picked_up.emit(picked_up_object)


# Remove copied collision shapes
func _remove_copied_collisions() -> void:
	if is_instance_valid(_collision_hand):
		for copied_collision: CopiedCollision in _active_copied_collisions:
			if is_instance_valid(copied_collision.collision_shape):
				_collision_hand.remove_child(copied_collision.collision_shape)
				copied_collision.collision_shape.queue_free()

	_active_copied_collisions.clear()


# When the grab collision mask has been modified
func _set_grab_collision_mask(new_value: int) -> void:
	grab_collision_mask = new_value
	if is_inside_tree() and _grab_area:
		_grab_area.collision_mask = new_value


# When the grab distance has been modified
func _set_grab_distance(new_value: float) -> void:
	grab_distance = new_value
	if is_inside_tree():
		_update_colliders()


# When the ranged-grab angle has been modified
func _set_ranged_angle(new_value: float) -> void:
	ranged_angle = new_value
	if is_inside_tree():
		_update_colliders()


# When the ranged-grab collision mask has been modified
func _set_ranged_collision_mask(new_value: int) -> void:
	ranged_collision_mask = new_value
	if is_inside_tree() and _ranged_area:
		_ranged_area.collision_mask = new_value


# When the ranged-grab distance has been modified
func _set_ranged_distance(new_value: float) -> void:
	ranged_distance = new_value
	if is_inside_tree():
		_update_colliders()


# Updates the best closest object field to grab
func _update_closest_object() -> void:
	# Find the closest object we can pickup
	var new_closest_obj: Node3D = null
	if not picked_up_object:
		# Find the closest in grab area
		new_closest_obj = _get_closest_grab()
		if not new_closest_obj and ranged_enable:
			# Find closest in ranged area
			new_closest_obj = _get_closest_ranged()

	# Skip if no change
	if closest_object == new_closest_obj:
		return

	# remove highlight on old object
	if is_instance_valid(closest_object):
		closest_object.request_highlight(self, false)

	# add highlight to new object
	closest_object = new_closest_obj
	if is_instance_valid(closest_object):
		closest_object.request_highlight(self, true)


# Updates the colliders' geometry
func _update_colliders() -> void:
	# Update the grab sphere
	if _grab_collision:
		_grab_collision.shape.radius = grab_distance

	# Update the ranged-grab cylinder
	if _ranged_collision:
		_ranged_collision.shape.radius = tan(deg_to_rad(ranged_angle)) * ranged_distance
		_ranged_collision.shape.height = ranged_distance
		_ranged_collision.transform.origin.z = -ranged_distance * 0.5


# Adjusts positions of our collisions to match actual location of object
func _update_copied_collisions() -> void:
	if is_instance_valid(_collision_hand) and is_instance_valid(picked_up_object):
		for copied_collision: CopiedCollision in _active_copied_collisions:
			if is_instance_valid(copied_collision.collision_shape):
				copied_collision.collision_shape.global_transform = picked_up_object.global_transform * \
					copied_collision.org_transform


# Class for storing copied collision data
class CopiedCollision extends RefCounted:
	var collision_shape: CollisionShape3D
	var org_transform: Transform3D
