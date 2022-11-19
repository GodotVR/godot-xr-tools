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

## Default hand pose
export var default_pose : Resource setget set_default_pose


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

## Sorted stack of PoseOverride
var _pose_overrides := []


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
	_update_pose()


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
func set_default_pose(pose : Resource) -> void:
	default_pose = pose
	if is_inside_tree():
		_update_pose()


## Add a pose override
func add_pose_override(who : Node, priority : int, settings : XRToolsHandPoseSettings) -> void:
	# Insert the pose override and update the pose
	_insert_pose_override(who, priority, settings)
	_update_pose()


## Remove a pose override
func remove_pose_override(who : Node) -> void:
	# Remove the pose override and update the pose
	_remove_pose_override(who)
	_update_pose()


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

			_animation_player.add_animation(open_name, open_pose)

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

			_animation_player.add_animation(closed_name, closed_pose)

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


func _remove_pose_override(who : Node) -> void:
	var pos := 0
	var length := _pose_overrides.size()

	# Iterate over all pose overrides in the list
	while pos < length:
		# Get the pose override
		var pose : PoseOverride = _pose_overrides[pos]

		# Check for a match
		if pose.who == who:
			# Remove the override
			_pose_overrides.remove(pos)
			length -= 1
		else:
			# Advance down the list
			pos += 1


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
