tool
class_name XRToolsHand, "res://addons/godot-xr-tools/editor/icons/hand.svg"
extends Spatial


##
## XR Hand Script
##
## @desc:
##     This script manages a godot-xr-tools hand. It animates the hand blending
##     grip and trigger animations based on controller input.
##
##     Additionally the hand script detects world-scale changes in the ARVRServer
##     and re-scales the hand appropriately so the hand stays scaled to the
##     physical hand of the user.
##

## Signal emitted when the hand scale changes
signal hand_scale_changed(scale)

## Override the hand material
export (Material) var hand_material_override setget set_hand_material_override

## Hand extends

export (Animation) var open_hand setget set_open_hand
export (Animation) var closed_hand setget set_closed_hand

func set_open_hand(p_new_hand : Animation):
	open_hand = p_new_hand
	if is_inside_tree():
		_update_hands()

func set_closed_hand(p_new_hand : Animation):
	closed_hand = p_new_hand
	if is_inside_tree():
		_update_hands()

func _update_hands():
	# our first child node should be our hand
	var hand_node : Spatial = get_child(0)
	if !hand_node:
		print("Couldn't find hand node")
		return

	var animation_player : AnimationPlayer = hand_node.get_node_or_null("AnimationPlayer")
	if !animation_player:
		print("Couldn't find animation player")
		return

	var animation_tree : AnimationTree = get_node_or_null("AnimationTree")
	if !animation_tree:
		print("Couldn't find animation tree")
		return

	var tree_root : AnimationNodeBlendTree = animation_tree.tree_root
	if !tree_root:
		print("Couldn't find tree root")
		return

	if open_hand:
		var open_name = animation_player.find_animation(open_hand)
		if open_name == "":
			open_name = "open_hand"
			if animation_player.has_animation(open_name):
				animation_player.remove_animation(open_name)

			animation_player.add_animation(open_name, open_hand)

		var open_hand_obj : AnimationNodeAnimation = tree_root.get_node("OpenHand")
		if open_hand_obj:
			open_hand_obj.animation = open_name

	if closed_hand:
		var closed_name = animation_player.find_animation(closed_hand)
		if closed_name == "":
			closed_name = "closed_hand"
			if animation_player.has_animation(closed_name):
				animation_player.remove_animation(closed_name)

			animation_player.add_animation(closed_name, closed_hand)

		var closed_hand_obj : AnimationNodeAnimation = tree_root.get_node("ClosedHand1")
		if closed_hand_obj:
			closed_hand_obj.animation = closed_name

		closed_hand_obj = tree_root.get_node("ClosedHand2")
		if closed_hand_obj:
			closed_hand_obj.animation = closed_name

## Last world scale (for scaling hands)
var _last_world_scale : float = 1.0

## Initial hand transform (from controller) - used for scaling hands
var _transform : Transform

## Hand mesh
var _hand_mesh : MeshInstance

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Save the initial hand transform
	_transform = transform
	
	# Find the hand mesh and update the hand material
	_hand_mesh = _find_mesh_instance(self)
	_update_hand_material_override()

	# As we're going to make modifications to our animation tree, we need to do
	# a deep copy, simply setting resource local to scene does not seem to be enough
	var tree_root = $AnimationTree.tree_root.duplicate(true)
	$AnimationTree.tree_root = tree_root
	
	# Make sure we're using the correct poses
	_update_hands()

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

		# Uncomment for workaround for bug in OpenXR plugin 1.1.1 and earlier giving values from -1.0 to 1.0
		# note that when controller are not being tracking yet this will result in a value of 0.5
		# grip = (grip + 1.0) * 0.5
		# trigger = (trigger + 1.0) * 0.5

		$AnimationTree.set("parameters/Grip/blend_amount", grip)
		$AnimationTree.set("parameters/Trigger/blend_amount", trigger)

		# var grip_state = controller.is_button_pressed(JOY_VR_GRIP)
		# print("Pressed: " + str(grip_state))

## Set the hand material override
func set_hand_material_override(material : Material) -> void:
	hand_material_override = material
	if is_inside_tree():
		_update_hand_material_override()


func _update_hand_material_override() -> void:
	if _hand_mesh:
		_hand_mesh.material_override = hand_material_override


func _find_mesh_instance(node : Node) -> MeshInstance:
	# Test if the node is a mesh
	var mesh := node as MeshInstance
	if mesh:
		return mesh

	# Check all children
	for i in node.get_child_count():
		mesh = _find_mesh_instance(node.get_child(i))
		if mesh:
			return mesh

	# Could not find mesh
	return null
