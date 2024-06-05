@tool
class_name XRToolsCollisionHand
extends XRToolsForceBody


## XRTools Collision Hand Container Script
##
## This script implements logic for collision hands. Specifically it tracks
## its ancestor [XRController3D], and can act as a container for hand models
## and pickup functions.


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
const DEFAULT_MASK := 0b0000_0000_0000_0000_1111_1111_1111_1111

# How much displacement is required for the hand to start orienting to a surface
const ORIENT_DISPLACEMENT := 0.05

# Distance to teleport hands
const TELEPORT_DISTANCE := 1.0


## Controls the hand collision mode
@export var mode : CollisionHandMode = CollisionHandMode.COLLIDE


# Controller to target (if no target overrides)
var _controller : XRController3D

# Sorted stack of TargetOverride
var _target_overrides := []

# Current target (controller or override)
var _target : Node3D


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


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsCollisionHand"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Disconnect from parent transform as we move to it in the physics step,
	# and boost the physics priority above any grab-drivers or hands.
	top_level = true
	process_physics_priority = -90

	# Populate nodes
	_controller = XRTools.find_xr_ancestor(self, "*", "XRController3D")

	# Update the target
	_update_target()


# Handle physics processing
func _physics_process(_delta):
	# Do not process if in the editor
	if Engine.is_editor_hint():
		return

	# Move to the current target
	_move_to_target()


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
func _move_to_target():
	# Handle DISABLED or no target
	if mode == CollisionHandMode.DISABLED or not _target:
		return

	# Handle TELEPORT
	if mode == CollisionHandMode.TELEPORT:
		global_transform = _target.global_transform
		return

	# Handle too far from target
	if global_position.distance_to(_target.global_position) > TELEPORT_DISTANCE:
		global_transform = _target.global_transform
		return

	# Orient the hand then move
	global_transform.basis = _target.global_transform.basis
	move_and_slide(_target.global_position - global_position)
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
