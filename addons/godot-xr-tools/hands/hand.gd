tool
class_name XRToolsHand, "res://addons/godot-xr-tools/editor/icons/hand.svg"
extends Spatial


## XR Tools Hand Script
##
## This script manages a godot-xr-tools hand. It animates the hand blending
## grip and trigger animations based on controller input.
##
## Additionally the hand script detects world-scale changes in the ARVRServer
## and re-scales the hand appropriately so the hand stays scaled to the
## physical hand of the user.


## Signal emitted when the hand scale changes
signal hand_scale_changed(scale)


## Override the hand material
export var hand_material_override : Material setget set_hand_material_override

## Default open-hand animation pose
export var open_hand : Animation setget set_open_hand

## Default close-hand animation pose
export var closed_hand : Animation setget set_closed_hand


## Last world scale (for scaling hands)
var _last_world_scale : float = 1.0

## Initial hand transform (from controller) - used for scaling hands
var _transform : Transform

## Hand mesh
var _hand_mesh : MeshInstance

## Hand animation player
var _animation_player : AnimationPlayer

## Hand animation tree
var _animation_tree : AnimationTree

## Animation blend tree
var _tree_root : AnimationNodeBlendTree

## Open-hand pose stack - keys (Node requesting override)
var _open_hand_stack_key := []

## Open-hand pose stack - poses (Animation to use)
var _open_hand_stack_pose := []

## Closed-hand pose stack - keys (Node requesting override)
var _closed_hand_stack_key := []

## Closed-hand pose stack - poses (Animation to use)
var _closed_hand_stack_pose := []


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Save the initial hand transform
	_transform = transform

	# Find the relevant hand nodes
	_hand_mesh = _find_child(self, "MeshInstance")
	_animation_player = _find_child(self, "AnimationPlayer")
	_animation_tree = _find_child(self, "AnimationTree")

	# As we're going to make modifications to our animation tree, we need to do
	# a deep copy, simply setting resource local to scene does not seem to be enough
	if _animation_tree:
		_tree_root = _animation_tree.tree_root.duplicate(true)
		_animation_tree.tree_root = _tree_root

	# Apply all updates
	_update_hand_material_override()
	_update_open_hand()
	_update_closed_hand()


## This method is called on every frame. It checks for world-scale changes and
## scales itself causing the hand mesh and skeleton to scale appropriately.
## It then reads the grip and trigger action values to animate the hand.
func _process(_delta: float) -> void:
	# Do not run physics if in the editor
	if Engine.editor_hint:
		return

	# Scale the hand mesh with the world scale. This is required for OpenXR plugin
	# 1.3.0 and later where the plugin no-longer scales the controllers with
	# world_scale
	if ARVRServer.world_scale != _last_world_scale:
		_last_world_scale = ARVRServer.world_scale
		transform = _transform.scaled(Vector3.ONE * _last_world_scale)
		emit_signal("hand_scale_changed", _last_world_scale)

	# Animate the hand mesh with the controller inputs
	var controller : ARVRController = get_parent()
	if controller:
		var grip = controller.get_joystick_axis(JOY_VR_ANALOG_GRIP)
		var trigger = controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)

		# Uncomment for workaround for bug in OpenXR plugin 1.1.1 and earlier
		# giving values from -1.0 to 1.0. Note that when controllers are not
		# being tracking yet this will result in a value of 0.5
		# grip = (grip + 1.0) * 0.5
		# trigger = (trigger + 1.0) * 0.5

		$AnimationTree.set("parameters/Grip/blend_amount", grip)
		$AnimationTree.set("parameters/Trigger/blend_amount", trigger)

		# var grip_state = controller.is_button_pressed(JOY_VR_GRIP)
		# print("Pressed: " + str(grip_state))


# This method verifies the hand has a valid configuration.
func _get_configuration_warning():
	# Check hand for mesh instance
	if not _find_child(self, "MeshInstance"):
		return "Hand does not have a MeshInstance"

	# Check hand for animation player
	if not _find_child(self, "AnimationPlayer"):
		return "Hand does not have a AnimationPlayer"

	# Check hand for animation tree
	var tree : AnimationTree = _find_child(self, "AnimationTree")
	if not tree:
		return "Hand does not have a AnimationTree"

	# Check hand animation tree has a root
	if not tree.tree_root:
		return "Hand AnimationTree has no root"

	# Passed basic validation
	return ""


## Set the hand material override
func set_hand_material_override(material : Material) -> void:
	hand_material_override = material
	if is_inside_tree():
		_update_hand_material_override()


## Set the default open-hand pose
func set_open_hand(p_new_hand : Animation) -> void:
	open_hand = p_new_hand
	if is_inside_tree():
		_update_open_hand()


## Set the default close-hand pose
func set_closed_hand(p_new_hand : Animation):
	closed_hand = p_new_hand
	if is_inside_tree():
		_update_closed_hand()


## Add a hand animation pose override
func add_hand_override(who : Node, open_pose : Animation, closed_pose : Animation) -> void:
	# Skip if invalid
	if !who:
		return

	# Add the open-pose to the open-hand stack and update the hands
	if open_pose:
		_open_hand_stack_key.push_back(who)
		_open_hand_stack_pose.push_back(open_pose)
		_update_open_hand()

	# Add the closed-pose to the closed-hand stack and update the hands
	if closed_pose:
		_closed_hand_stack_key.push_back(who)
		_closed_hand_stack_pose.push_back(closed_pose)
		_update_closed_hand()


## Remove a hand animation pose override
func remove_hand_override(who : Node) -> void:
	# Remove from the open-hand pose stack
	if _remove_hand_pose(who, _open_hand_stack_key, _open_hand_stack_pose):
		_update_open_hand()

	# Remove from the closed-hand pose stack
	if _remove_hand_pose(who, _closed_hand_stack_key, _closed_hand_stack_pose):
		_update_closed_hand()


func _update_hand_material_override() -> void:
	if _hand_mesh:
		_hand_mesh.material_override = hand_material_override


func _update_open_hand() -> void:
	# Skip if no blend tree
	if !_tree_root:
		return

	# Find the open pose to use
	var open_pose := open_hand
	if _open_hand_stack_pose.size():
		open_pose = _open_hand_stack_pose.back()

	# Apply the closed hand pose in the player and blend tree
	if open_pose:
		var open_name = _animation_player.find_animation(open_pose)
		if open_name == "":
			open_name = "open_hand"
			if _animation_player.has_animation(open_name):
				_animation_player.remove_animation(open_name)

			_animation_player.add_animation(open_name, open_pose)

		var open_hand_obj : AnimationNodeAnimation = _tree_root.get_node("OpenHand")
		if open_hand_obj:
			open_hand_obj.animation = open_name


func _update_closed_hand() -> void:
	# Skip if no blend tree
	if !_tree_root:
		return

	# Find the close pose to use
	var closed_pose := closed_hand
	if _closed_hand_stack_pose.size():
		closed_pose = _closed_hand_stack_pose.back()

	# Apply the closed hand pose in the player and blend tree
	if closed_hand:
		var closed_name = _animation_player.find_animation(closed_pose)
		if closed_name == "":
			closed_name = "closed_hand"
			if _animation_player.has_animation(closed_name):
				_animation_player.remove_animation(closed_name)

			_animation_player.add_animation(closed_name, closed_pose)

		var closed_hand_obj : AnimationNodeAnimation = _tree_root.get_node("ClosedHand1")
		if closed_hand_obj:
			closed_hand_obj.animation = closed_name

		closed_hand_obj = _tree_root.get_node("ClosedHand2")
		if closed_hand_obj:
			closed_hand_obj.animation = closed_name


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


static func _remove_hand_pose(who : Node, keys : Array, poses : Array) -> bool:
	# Look for keys to remove
	var modified := false
	while true:
		# Break if no key found
		var pos := keys.find_last(who)
		if pos < 0:
			break

		# Remove pose override from the stack
		keys.remove(pos)
		poses.remove(pos)
		modified = true

	# Return modified flag
	return modified
