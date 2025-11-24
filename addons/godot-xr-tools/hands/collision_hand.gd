@tool
class_name XRToolsCollisionHand
extends XRToolsForceBody


## XRTools Collision Hand Container Script
##
## This script implements logic for collision hands. Specifically it tracks
## its ancestor [XRController3D], and can act as a container for hand models
## and pickup functions.

# We reached our teleport distance
signal max_distance_reached

## Modes for collision hand
enum CollisionHandMode {
	## Hand is disabled and must be moved externally
	DISABLED,

	## Hand teleports to controller
	TELEPORT,

	## Hand collides with world (based on mask)
	COLLIDE
}

# Default layer of 18:player-hands
const DEFAULT_LAYER := 0b0000_0000_0000_0010_0000_0000_0000_0000

# Default mask of 0xFFFF (1..16)
# - 1:static-world
# - 2:dynamic-world
# - 3:pickable-objects
# - 4:wall-walking
# - 5:grappling-target
const DEFAULT_MASK := 0b0000_0000_0000_0101_0000_0000_0001_1111

# How much displacement is required for the hand to start orienting to a surface
const ORIENT_DISPLACEMENT := 0.05

# Distance to teleport hands
const TELEPORT_DISTANCE := 1.0

## Controls the hand collision mode
@export var mode : CollisionHandMode = CollisionHandMode.COLLIDE


## Links to skeleton that adds finger digits
@export var hand_skeleton : Skeleton3D:
	set(value):
		if hand_skeleton == value:
			return

		if hand_skeleton:
			if hand_skeleton.has_signal("skeleton_updated"):
				# Godot 4.3+
				hand_skeleton.skeleton_updated.disconnect(_on_skeleton_updated)
			else:
				hand_skeleton.pose_updated.disconnect(_on_skeleton_updated)
			for digit in _digit_collision_shapes:
				var shape : CollisionShape3D = _digit_collision_shapes[digit]
				remove_child(shape)
				shape.queue_free()
			_digit_collision_shapes.clear()

		hand_skeleton = value
		if hand_skeleton and is_inside_tree():
			_update_hand_skeleton()

		notify_property_list_changed()


## Minimum force we can exert on a picked up object
@export_range(1.0, 1000.0, 0.1, "suffix:N") var min_pickup_force : float = 15.0

## Force we exert on a picked up object when hand is at maximum distance
## before letting go.
@export_range(1.0, 1000.0, 0.1, "suffix:N") var max_pickup_force : float = 300.0


# Controller to target (if no target overrides)
var _controller : XRController3D

# Sorted stack of TargetOverride
var _target_overrides := []

# Current target (controller or override)
var _target : Node3D

# Skeleton collisions
var _palm_collision_shape : CollisionShape3D
var _digit_collision_shapes : Dictionary

# The weight held by this hand
var _held_weight : float = 0.0

# Movement on last frame
var _last_movement : Vector3 = Vector3()

## Target-override class
class TargetOverride:
	## Target of the override
	var target : Node3D

	## Target priority
	var priority : int

	## Target-override constructor
	func _init(t : Node3D, p : int):
		target = t
		priority = p


# Update the weight attributed to this hand (updated from pickable system).
func set_held_weight(new_weight):
	_held_weight = new_weight


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsCollisionHand"


# Return warnings related to this node
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check palm node
	if not _palm_collision_shape:
		warnings.push_back("Collision hand scenes are deprecated, use collision node script directly.")

	# Check if skeleton is a child
	if hand_skeleton and not is_ancestor_of(hand_skeleton):
		warnings.push_back("The hand skeleton node should be within the tree of this node.")

	# Return warnings
	return warnings


# Called when the node enters the scene tree for the first time.
func _ready():
	var palm_collision : CollisionShape3D = get_node_or_null("CollisionShape3D")
	if not palm_collision:
		# We create our object even in editor to supress our warning.
		# This allows us to just add an XRToolsCollisionHand node without
		# using our scene.
		_palm_collision_shape = CollisionShape3D.new()
		_palm_collision_shape.name = "Palm"
		_palm_collision_shape.shape = \
			preload("res://addons/godot-xr-tools/hands/scenes/collision/hand_palm.shape")
		_palm_collision_shape.transform.origin = Vector3(0.0, -0.05, 0.11)
		add_child(_palm_collision_shape, false, Node.INTERNAL_MODE_BACK)
	elif not Engine.is_editor_hint():
		# Use our existing collision shape node but only in runtime.
		# In editor we can check this to provide a deprecation warning.
		palm_collision.name = "Palm"
		_palm_collision_shape = palm_collision

	_update_hand_skeleton()

	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Disconnect from parent transform as we move to it in the physics step,
	# and boost the physics priority above any grab-drivers or hands.
	top_level = true
	process_physics_priority = -90
	sync_to_physics = false

	# Connect to player body signals (if applicable)
	var player_body = XRToolsPlayerBody.find_instance(self)
	if player_body:
		player_body.player_moved.connect(_on_player_moved)
		player_body.player_teleported.connect(_on_player_teleported)

	# Populate nodes
	_controller = XRTools.find_xr_ancestor(self, "*", "XRController3D")

	# Update the target
	_update_target()


# Handle physics processing
func _physics_process(delta):
	# Do not process if in the editor
	if Engine.is_editor_hint():
		return

	var current_position = global_position

	# Move to the current target
	_move_to_target(delta)

	_last_movement = global_position - current_position

## This function adds a target override. The collision hand will attempt to
## move to the highest priority target, or the [XRController3D] if no override
## is specified.
func add_target_override(target : Node3D, priority : int) -> void:
	# Remove any existing target override from this source
	var modified := _remove_target_override(target)

	# Insert the target override
	_insert_target_override(target, priority)
	modified = true

	# Update the target
	if modified:
		_update_target()


## This function remove a target override.
func remove_target_override(target : Node3D) -> void:
	# Remove the target override
	var modified := _remove_target_override(target)

	# Update the pose
	if modified:
		_update_target()


## This function searches from the specified node for an [XRToolsCollisionHand]
## assuming the node is a sibling of the hand under an [XRController3D].
static func find_instance(node : Node) -> XRToolsCollisionHand:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_controller(node),
		"*",
		"XRToolsCollisionHand") as XRToolsCollisionHand

## This function searches an [XRToolsCollisionHand] that is an ancestor
## of the given node.
static func find_ancestor(node : Node) -> XRToolsCollisionHand:
	return XRTools.find_xr_ancestor(
		node,
		"*",
		"XRToolsCollisionHand") as XRToolsCollisionHand


## This function searches from the specified node for the left controller
## [XRToolsCollisionHand] assuming the node is a sibling of the [XROrigin3D].
static func find_left(node : Node) -> XRToolsCollisionHand:
	return XRTools.find_xr_child(
		XRHelpers.get_left_controller(node),
		"*",
		"XRToolsCollisionHand") as XRToolsCollisionHand


## This function searches from the specified node for the right controller
## [XRToolsCollisionHand] assuming the node is a sibling of the [XROrigin3D].
static func find_right(node : Node) -> XRToolsCollisionHand:
	return XRTools.find_xr_child(
		XRHelpers.get_right_controller(node),
		"*",
		"XRToolsCollisionHand") as XRToolsCollisionHand


# This function moves the collision hand to the target node.
func _move_to_target(delta):
	# Handle DISABLED or no target
	if mode == CollisionHandMode.DISABLED or not _target:
		return

	# Handle TELEPORT
	if mode == CollisionHandMode.TELEPORT:
		global_transform = _target.global_transform
		return

	# Handle too far from target
	if global_position.distance_to(_target.global_position) > TELEPORT_DISTANCE:
		max_distance_reached.emit()

		global_transform = _target.global_transform
		return

	# Orient the hand
	rotate_and_collide(_target.global_basis)

	# Adjust target position if we're holding something
	var target_movement : Vector3 = _target.global_position - global_position
	if _held_weight > 0.0:
		var gravity_state := PhysicsServer3D.body_get_direct_state(get_rid())
		var gravity = gravity_state.total_gravity * delta

		# Calculate the movement of our held object if we weren't holding it
		var base_movement : Vector3 = _last_movement * 0.2 + gravity

		# How much movement is left until we reach our target
		var remaining_movement = target_movement - base_movement

		# The below is an approximation as we're not taking the logarithmic
		# nature of force acceleration into account for simplicitiy.

		# Distance over time gives our needed acceleration which
		# gives us the force needed on the object to move it to our
		# target destination.
		# But dividing and then multiplying over delta and mass is wasteful.
		var needed_distance = remaining_movement.length()

		# Force we can exert on the object
		var force = min_pickup_force + \
			(target_movement.length() * (max_pickup_force-min_pickup_force) / TELEPORT_DISTANCE)

		# How much can we move our object?
		var possible_distance = delta * force / _held_weight
		if possible_distance < needed_distance:
			# We can't make our distance? adjust our movement!
			remaining_movement *= (possible_distance / needed_distance)
			target_movement = base_movement + remaining_movement

	# And move
	move_and_slide(target_movement)
	force_update_transform()


# If our player moved, attempt to move our hand but ignoring weight.
func _on_player_moved(delta_transform : Transform3D):
	if mode == CollisionHandMode.DISABLED:
		return

	if mode == CollisionHandMode.TELEPORT:
		_on_player_teleported(delta_transform)
		return

	var target : Transform3D = delta_transform * global_transform

	# Rotate
	rotate_and_collide(target.basis)

	# And attempt to move
	move_and_slide(target.origin - global_position)
	force_update_transform()


# If our player teleported, just move.
func _on_player_teleported(delta_transform : Transform3D):
	if mode == CollisionHandMode.DISABLED:
		return

	global_transform = delta_transform * global_transform
	force_update_transform()


# This function inserts a target override into the overrides list by priority
# order.
func _insert_target_override(target : Node3D, priority : int) -> void:
	# Construct the target override
	var override := TargetOverride.new(target, priority)

	# Iterate over all target overrides in the list
	for pos in _target_overrides.size():
		# Get the target override
		var o : TargetOverride = _target_overrides[pos]

		# Insert as early as possible to not invalidate sorting
		if o.priority <= priority:
			_target_overrides.insert(pos, override)
			return

	# Insert at the end
	_target_overrides.push_back(override)


# This function removes a target from the overrides list
func _remove_target_override(target : Node) -> bool:
	var pos := 0
	var length := _target_overrides.size()
	var modified := false

	# Iterate over all pose overrides in the list
	while pos < length:
		# Get the target override
		var o : TargetOverride = _target_overrides[pos]

		# Check for a match
		if o.target == target:
			# Remove the override
			_target_overrides.remove_at(pos)
			modified = true
			length -= 1
		else:
			# Advance down the list
			pos += 1

	# Return the modified indicator
	return modified


# This function updates the target for hand movement.
func _update_target() -> void:
	# Start by assuming the controller
	_target = _controller

	# Use first target override if specified
	if _target_overrides.size():
		_target = _target_overrides[0].target


# If a skeleton is set, update.
func _update_hand_skeleton():
	if hand_skeleton:
		if hand_skeleton.has_signal("skeleton_updated"):
			# Godot 4.3+
			hand_skeleton.skeleton_updated.connect(_on_skeleton_updated)
		else:
			hand_skeleton.pose_updated.connect(_on_skeleton_updated)

		# Run atleast once to init
		_on_skeleton_updated()


# Update our finger digits when our skeleton updates
func _on_skeleton_updated():
	if not hand_skeleton:
		return

	var bone_count = hand_skeleton.get_bone_count()
	for i in bone_count:
		var collision_node : CollisionShape3D
		var offset : Transform3D
		offset.origin = Vector3(0.0, 0.015, 0.0) # move to side of joint

		var bone_name = hand_skeleton.get_bone_name(i)
		if bone_name == "Palm_L":
			offset.origin = Vector3(-0.02, 0.025, 0.0) # move to side of joint
			collision_node = _palm_collision_shape
		elif bone_name == "Palm_R":
			offset.origin = Vector3(0.02, 0.025, 0.0) # move to side of joint
			collision_node = _palm_collision_shape
		elif bone_name.contains("Proximal") or bone_name.contains("Intermediate") or \
			bone_name.contains("Distal"):
			if _digit_collision_shapes.has(bone_name):
				collision_node = _digit_collision_shapes[bone_name]
			else:
				collision_node = CollisionShape3D.new()
				collision_node.name = bone_name
				collision_node.shape = \
					preload("res://addons/godot-xr-tools/hands/scenes/collision/hand_digit.shape")
				add_child(collision_node, false, Node.INTERNAL_MODE_BACK)
				_digit_collision_shapes[bone_name] = collision_node

		if collision_node:
			# TODO it would require a far more complex approach,
			# but being able to check if our collision shapes can move to their new locations
			# would be interesting.

			collision_node.transform = global_transform.inverse() \
				* hand_skeleton.global_transform \
				* hand_skeleton.get_bone_global_pose(i) \
				* offset
