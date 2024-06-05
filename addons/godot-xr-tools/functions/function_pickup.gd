@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsFunctionPickup
extends Node3D


## XR Tools Function Pickup Script
##
## This script implements picking up of objects. Most pickable
## objects are instances of the [XRToolsPickable] class.
##
## Additionally this script can work in conjunction with the
## [XRToolsMovementProvider] class support climbing. Most climbable objects are
## instances of the [XRToolsClimbable] class.


## Signal emitted when the pickup picks something up
signal has_picked_up(what)

## Signal emitted when the pickup drops something
signal has_dropped


# Default pickup collision mask of 3:pickable and 19:handle
const DEFAULT_GRAB_MASK := 0b0000_0000_0000_0100_0000_0000_0000_0100

# Default pickup collision mask of 3:pickable
const DEFAULT_RANGE_MASK := 0b0000_0000_0000_0000_0000_0000_0000_0100

# Constant for worst-case grab distance
const MAX_GRAB_DISTANCE2: float = 1000000.0


## Pickup enabled property
@export var enabled : bool = true

## Grip controller axis
@export var pickup_axis_action : String = "grip"

## Action controller button
@export var action_button_action : String = "trigger_click"

## Grab distance
@export var grab_distance : float = 0.3: set = _set_grab_distance

## Grab collision mask
@export_flags_3d_physics \
		var grab_collision_mask : int = DEFAULT_GRAB_MASK: set = _set_grab_collision_mask

## If true, ranged-grabbing is enabled
@export var ranged_enable : bool = true

## Ranged-grab distance
@export var ranged_distance : float = 5.0: set = _set_ranged_distance

## Ranged-grab angle
@export_range(0.0, 45.0) var ranged_angle : float = 5.0: set = _set_ranged_angle

## Ranged-grab collision mask
@export_flags_3d_physics \
		var ranged_collision_mask : int = DEFAULT_RANGE_MASK: set = _set_ranged_collision_mask

## Throw impulse factor
@export var impulse_factor : float = 1.0

## Throw velocity averaging
@export var velocity_samples: int = 5


# Public fields
var closest_object : Node3D = null
var picked_up_object : Node3D = null
var picked_up_ranged : bool = false
var grip_pressed : bool = false

# Private fields
var _object_in_grab_area := Array()
var _object_in_ranged_area := Array()
var _velocity_averager := XRToolsVelocityAverager.new(velocity_samples)
var _grab_area : Area3D
var _grab_collision : CollisionShape3D
var _ranged_area : Area3D
var _ranged_collision : CollisionShape3D


## Controller
@onready var _controller := XRHelpers.get_xr_controller(self)

## Grip threshold (from configuration)
@onready var _grip_threshold : float = XRTools.get_grip_threshold()


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsFunctionPickup"


# Called when the node enters the scene tree for the first time.
func _ready():
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

	# Monitor Grab Button
	_controller.connect("button_pressed", _on_button_pressed)
	_controller.connect("button_released", _on_button_released)


# Called on each frame to update the pickup
func _process(delta):
	# Do not process if in the editor
	if Engine.is_editor_hint():
		return

	# Skip if disabled, or the controller isn't active
	if !enabled or !_controller.get_is_active():
		return

	# Handle our grip
	var grip_value = _controller.get_float(pickup_axis_action)
	if (grip_pressed and grip_value < (_grip_threshold - 0.1)):
		grip_pressed = false
		_on_grip_release()
	elif (!grip_pressed and grip_value > (_grip_threshold + 0.1)):
		grip_pressed = true
		_on_grip_pressed()

	# Calculate average velocity
	if is_instance_valid(picked_up_object) and picked_up_object.is_picked_up():
		# Average velocity of picked up object
		_velocity_averager.add_transform(delta, picked_up_object.global_transform)
	else:
		# Average velocity of this pickup
		_velocity_averager.add_transform(delta, global_transform)

	_update_closest_object()


## Find an [XRToolsFunctionPickup] node.
##
## This function searches from the specified node for an [XRToolsFunctionPickup]
## assuming the node is a sibling of the pickup under an [XRController3D].
static func find_instance(node : Node) -> XRToolsFunctionPickup:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_controller(node),
		"*",
		"XRToolsFunctionPickup") as XRToolsFunctionPickup


## Find the left [XRToolsFunctionPickup] node.
##
## This function searches from the specified node for the left controller
## [XRToolsFunctionPickup] assuming the node is a sibling of the [XOrigin3D].
static func find_left(node : Node) -> XRToolsFunctionPickup:
	return XRTools.find_xr_child(
		XRHelpers.get_left_controller(node),
		"*",
		"XRToolsFunctionPickup") as XRToolsFunctionPickup


## Find the right [XRToolsFunctionPickup] node.
##
## This function searches from the specified node for the right controller
## [XRToolsFunctionPickup] assuming the node is a sibling of the [XROrigin3D].
static func find_right(node : Node) -> XRToolsFunctionPickup:
	return XRTools.find_xr_child(
		XRHelpers.get_right_controller(node),
		"*",
		"XRToolsFunctionPickup") as XRToolsFunctionPickup


## Get the [XRController3D] driving this pickup.
func get_controller() -> XRController3D:
	return _controller


# Called when the grab distance has been modified
func _set_grab_distance(new_value: float) -> void:
	grab_distance = new_value
	if is_inside_tree():
		_update_colliders()


# Called when the grab collision mask has been modified
func _set_grab_collision_mask(new_value: int) -> void:
	grab_collision_mask = new_value
	if is_inside_tree() and _grab_collision:
		_grab_collision.collision_mask = new_value


# Called when the ranged-grab distance has been modified
func _set_ranged_distance(new_value: float) -> void:
	ranged_distance = new_value
	if is_inside_tree():
		_update_colliders()


# Called when the ranged-grab angle has been modified
func _set_ranged_angle(new_value: float) -> void:
	ranged_angle = new_value
	if is_inside_tree():
		_update_colliders()


# Called when the ranged-grab collision mask has been modified
func _set_ranged_collision_mask(new_value: int) -> void:
	ranged_collision_mask = new_value
	if is_inside_tree() and _ranged_collision:
		_ranged_collision.collision_mask = new_value


# Update the colliders geometry
func _update_colliders() -> void:
	# Update the grab sphere
	if _grab_collision:
		_grab_collision.shape.radius = grab_distance

	# Update the ranged-grab cylinder
	if _ranged_collision:
		_ranged_collision.shape.radius = tan(deg_to_rad(ranged_angle)) * ranged_distance
		_ranged_collision.shape.height = ranged_distance
		_ranged_collision.transform.origin.z = -ranged_distance * 0.5


# Called when an object enters the grab sphere
func _on_grab_entered(target: Node3D) -> void:
	# reject objects which don't support picking up
	if not target.has_method('pick_up'):
		return

	# ignore objects already known
	if _object_in_grab_area.find(target) >= 0:
		return

	# Add to the list of objects in grab area
	_object_in_grab_area.push_back(target)


# Called when an object enters the ranged-grab cylinder
func _on_ranged_entered(target: Node3D) -> void:
	# reject objects which don't support picking up rangedly
	if not 'can_ranged_grab' in target or not target.can_ranged_grab:
		return

	# ignore objects already known
	if _object_in_ranged_area.find(target) >= 0:
		return

	# Add to the list of objects in grab area
	_object_in_ranged_area.push_back(target)


# Called when an object exits the grab sphere
func _on_grab_exited(target: Node3D) -> void:
	_object_in_grab_area.erase(target)


# Called when an object exits the ranged-grab cylinder
func _on_ranged_exited(target: Node3D) -> void:
	_object_in_ranged_area.erase(target)


# Update the closest object field with the best choice of grab
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


# Find the pickable object closest to our hand's grab location
func _get_closest_grab() -> Node3D:
	var new_closest_obj: Node3D = null
	var new_closest_distance := MAX_GRAB_DISTANCE2
	for o in _object_in_grab_area:
		# skip objects that can not be picked up
		if not o.can_pick_up(self):
			continue

		# Save if this object is closer than the current best
		var distance_squared := global_transform.origin.distance_squared_to(
				o.global_transform.origin)
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
	for o in _object_in_ranged_area:
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


## Drop the currently held object
func drop_object() -> void:
	if not is_instance_valid(picked_up_object):
		return

	# let go of this object
	picked_up_object.let_go(
		self,
		_velocity_averager.linear_velocity() * impulse_factor,
		_velocity_averager.angular_velocity())
	picked_up_object = null
	emit_signal("has_dropped")


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
		picked_up_object.request_highlight(self, false)
		emit_signal("has_picked_up", picked_up_object)


func _on_button_pressed(p_button) -> void:
	if p_button == action_button_action:
		if is_instance_valid(picked_up_object) and picked_up_object.has_method("action"):
			picked_up_object.action()


func _on_button_released(_p_button) -> void:
	pass


func _on_grip_pressed() -> void:
	if is_instance_valid(picked_up_object) and !picked_up_object.press_to_hold:
		drop_object()
	elif is_instance_valid(closest_object):
		_pick_up_object(closest_object)


func _on_grip_release() -> void:
	if is_instance_valid(picked_up_object) and picked_up_object.press_to_hold:
		drop_object()
