@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name XRToolsHand
extends Node3D


## XR Tools Hand Script
##
## This script manages a godot-xr-tools hand. It animates the hand blending
## grip and trigger animations based on controller input.
##
## Additionally the hand script detects world-scale changes in the XRServer
## and re-scales the hand appropriately so the hand stays scaled to the
## physical hand of the user.


## Signal emitted when the hand scale changes
signal hand_scale_changed(scale)


## Blend tree to use
@export var hand_blend_tree : AnimationNodeBlendTree: set = set_hand_blend_tree

## Override the hand material
@export var hand_material_override : Material: set = set_hand_material_override

## Default hand pose
@export var default_pose : XRToolsHandPoseSettings: set = set_default_pose

## Name of the Grip action in the OpenXR Action Map.
@export var grip_action : String = "grip"

## Name of the Trigger action in the OpenXR Action Map.
@export var trigger_action : String = "trigger"


## Last world scale (for scaling hands)
var _last_world_scale : float = 1.0

## Controller used for input/tracking
var _controller : XRController3D

## Initial hand transform (from controller) - used for scaling hands
var _initial_transform : Transform3D

## Current hand transform (from controller) - after scale
var _transform : Transform3D

## Hand mesh
var _hand_mesh : MeshInstance3D

## Hand animation player
var _animation_player : AnimationPlayer

## Hand animation tree
var _animation_tree : AnimationTree

## Animation blend tree
var _tree_root : AnimationNodeBlendTree

## Sorted stack of PoseOverride
var _pose_overrides := []

## Force grip value (< 0 for no force)
var _force_grip := -1.0

## Force trigger value (< 0 for no force)
var _force_trigger := -1.0

# Sorted stack of TargetOverride
var _target_overrides := []

# Current target (controller or override)
var _target : Node3D


## Pose-override class
class PoseOverride:
	## Who requested the override
	var who : Node

	## Pose priority
	var priority : int

	## Pose settings
	var settings : XRToolsHandPoseSettings

	## Pose-override constructor
	func _init(w : Node, p : int, s : XRToolsHandPoseSettings):
		who = w
		priority = p
		settings = s


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
	return name == "XRToolsHand"


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Save the initial hand transform
	_initial_transform = transform
	_transform = _initial_transform

	# Disconnect from parent transform as we move to it in the physics step,
	# and boost the physics priority after any grab-drivers but before other
	# processing.
	if not Engine.is_editor_hint():
		top_level = true
		process_physics_priority = -70

	# Find our controller
	_controller = XRTools.find_xr_ancestor(self, "*", "XRController3D")

	# Find the relevant hand nodes
	_hand_mesh = _find_child(self, "MeshInstance3D")
	_animation_player = _find_child(self, "AnimationPlayer")
	_animation_tree = _find_child(self, "AnimationTree")

	# Apply all updates
	_update_hand_blend_tree()
	_update_hand_material_override()
	_update_pose()
	_update_target()


## This method checks for world-scale changes and scales itself causing the
## hand mesh and skeleton to scale appropriately. It then reads the grip and
## trigger action values to animate the hand.
func _physics_process(_delta: float) -> void:
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return

	# Scale the hand mesh with the world scale.
	if XRServer.world_scale != _last_world_scale:
		_last_world_scale = XRServer.world_scale
		_transform = _initial_transform.scaled(Vector3.ONE * _last_world_scale)
		emit_signal("hand_scale_changed", _last_world_scale)

	# Animate the hand mesh with the controller inputs
	if _controller:
		var grip : float = _controller.get_float(grip_action)
		var trigger : float = _controller.get_float(trigger_action)

		# Allow overriding of grip and trigger
		if _force_grip >= 0.0: grip = _force_grip
		if _force_trigger >= 0.0: trigger = _force_trigger

		$AnimationTree.set("parameters/Grip/blend_amount", grip)
		$AnimationTree.set("parameters/Trigger/blend_amount", trigger)

	# Move to target
	global_transform = _target.global_transform * _transform
	force_update_transform()


# This method verifies the hand has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check hand for mesh instance
	if not _find_child(self, "MeshInstance3D"):
		warnings.append("Hand does not have a MeshInstance3D")

	# Check hand for animation player
	if not _find_child(self, "AnimationPlayer"):
		warnings.append("Hand does not have a AnimationPlayer")

	# Check hand for animation tree
	var tree : AnimationTree = _find_child(self, "AnimationTree")
	if not tree:
		warnings.append("Hand does not have a AnimationTree")
	elif not tree.tree_root:
		warnings.append("Hand AnimationTree has no root")

	# Return warnings
	return warnings


## Find an [XRToolsHand] node.
##
## This function searches from the specified node for an [XRToolsHand] assuming
## the node is a sibling of the hand under an [XROrigin3D].
static func find_instance(node : Node) -> XRToolsHand:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_controller(node),
		"*",
		"XRToolsHand") as XRToolsHand


## This function searches from the specified node for the left controller
## [XRToolsHand] assuming the node is a sibling of the [XROrigin3D].
static func find_left(node : Node) -> XRToolsHand:
	return XRTools.find_xr_child(
		XRHelpers.get_left_controller(node),
		"*",
		"XRToolsHand") as XRToolsHand


## This function searches from the specified node for the right controller
## [XRToolsHand] assuming the node is a sibling of the [XROrigin3D].
static func find_right(node : Node) -> XRToolsHand:
	return XRTools.find_xr_child(
		XRHelpers.get_right_controller(node),
		"*",
		"XRToolsHand") as XRToolsHand


## Set the blend tree
func set_hand_blend_tree(blend_tree : AnimationNodeBlendTree) -> void:
	hand_blend_tree = blend_tree
	if is_inside_tree():
		_update_hand_blend_tree()
		_update_pose()


## Set the hand material override
func set_hand_material_override(material : Material) -> void:
	hand_material_override = material
	if is_inside_tree():
		_update_hand_material_override()


## Set the default open-hand pose
func set_default_pose(pose : XRToolsHandPoseSettings) -> void:
	default_pose = pose
	if is_inside_tree():
		_update_pose()


## Add a pose override
func add_pose_override(who : Node, priority : int, settings : XRToolsHandPoseSettings) -> void:
	# Remove any existing pose override from this source
	var modified := _remove_pose_override(who)

	# Insert the pose override
	if settings:
		_insert_pose_override(who, priority, settings)
		modified = true

	# Update the pose
	if modified:
		_update_pose()


## Remove a pose override
func remove_pose_override(who : Node) -> void:
	# Remove the pose override
	var modified := _remove_pose_override(who)

	# Update the pose
	if modified:
		_update_pose()


## Force the grip and trigger values (primarily for preview)
func force_grip_trigger(grip : float = -1.0, trigger : float = -1.0) -> void:
	# Save the forced values
	_force_grip = grip
	_force_trigger = trigger

	# Update the animation if forcing to specific values
	if grip >= 0.0: $AnimationTree.set("parameters/Grip/blend_amount", grip)
	if trigger >= 0.0: $AnimationTree.set("parameters/Trigger/blend_amount", trigger)


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


func _update_hand_blend_tree() -> void:
	# As we're going to make modifications to our animation tree, we need to do
	# a deep copy, simply setting resource local to scene does not seem to be enough
	if _animation_tree and hand_blend_tree:
		_tree_root = hand_blend_tree.duplicate(true)
		_animation_tree.tree_root = _tree_root


func _update_hand_material_override() -> void:
	if _hand_mesh:
		_hand_mesh.material_override = hand_material_override


func _update_pose() -> void:
	# Skip if no blend tree
	if !_tree_root:
		return

	# Select the pose settings
	var pose_settings : XRToolsHandPoseSettings = default_pose
	if _pose_overrides.size():
		pose_settings = _pose_overrides[0].settings

	# Get the open and closed pose animations
	var open_pose : Animation = pose_settings.open_pose
	var closed_pose : Animation = pose_settings.closed_pose

	# Apply the open hand pose in the player and blend tree
	if open_pose:
		var open_name = _animation_player.find_animation(open_pose)
		if open_name == "":
			open_name = "open_hand"
			if _animation_player.has_animation(open_name):
				_animation_player.remove_animation(open_name)

			_animation_player.get_animation_library("").add_animation(open_name, open_pose)

		var open_hand_obj : AnimationNodeAnimation = _tree_root.get_node("OpenHand")
		if open_hand_obj:
			open_hand_obj.animation = open_name

	# Apply the closed hand pose in the player and blend tree
	if closed_pose:
		var closed_name = _animation_player.find_animation(closed_pose)
		if closed_name == "":
			closed_name = "closed_hand"
			if _animation_player.has_animation(closed_name):
				_animation_player.remove_animation(closed_name)

			_animation_player.get_animation_library("").add_animation(closed_name, closed_pose)

		var closed_hand_obj : AnimationNodeAnimation = _tree_root.get_node("ClosedHand1")
		if closed_hand_obj:
			closed_hand_obj.animation = closed_name

		closed_hand_obj = _tree_root.get_node("ClosedHand2")
		if closed_hand_obj:
			closed_hand_obj.animation = closed_name


func _insert_pose_override(who : Node, priority : int, settings : XRToolsHandPoseSettings) -> void:
	# Construct the pose override
	var override := PoseOverride.new(who, priority, settings)

	# Iterate over all pose overrides in the list
	for pos in _pose_overrides.size():
		# Get the pose override
		var pose : PoseOverride = _pose_overrides[pos]

		# Insert as early as possible to not invalidate sorting
		if pose.priority <= priority:
			_pose_overrides.insert(pos, override)
			return

	# Insert at the end
	_pose_overrides.push_back(override)


func _remove_pose_override(who : Node) -> bool:
	var pos := 0
	var length := _pose_overrides.size()
	var modified := false

	# Iterate over all pose overrides in the list
	while pos < length:
		# Get the pose override
		var pose : PoseOverride = _pose_overrides[pos]

		# Check for a match
		if pose.who == who:
			# Remove the override
			_pose_overrides.remove_at(pos)
			modified = true
			length -= 1
		else:
			# Advance down the list
			pos += 1

	# Return the modified indicator
	return modified


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
	if _target_overrides.size():
		_target = _target_overrides[0].target
	else:
		_target = get_parent()


static func _find_child(node : Node, type : String) -> Node:
	# Iterate through all children
	for child in node.get_children():
		# If the child is a match then return it
		if child.is_class(type):
			return child

		# Recurse into child
		var found := _find_child(child, type)
		if found:
			return found

	# No child found matching type
	return null
