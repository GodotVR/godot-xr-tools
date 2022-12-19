@tool
class_name XRToolsHand
extends Node3D
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")


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


## Override the hand material
@export var hand_material_override : Material: set = set_hand_material_override

## Name of the Grip action in the OpenXR Action Map.
@export var grip_action : String = "grip"

## Name of the Trigger action in the OpenXR Action Map.
@export var trigger_action : String = "trigger"

## World scale - used for scaling hands
var _world_scale : float = 1.0


## Initial hand transform (from controller) - used for scaling hands
@onready var _transform : Transform3D

## Hand mesh
var _hand_mesh : MeshInstance3D

## Force grip value (< 0 for no force)
var _force_grip := -1.0

## Force trigger value (< 0 for no force)
var _force_trigger := -1.0

# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsHand"


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Save the initial hand transform
	_transform = transform

	# Find the relevant hand nodes
	_hand_mesh = _find_child(self, "MeshInstance3D")

	# Apply all updates
	_update_hand_material_override()


## This method is called on every frame. It checks for world-scale changes and
## scales itself causing the hand mesh and skeleton to scale appropriately.
## It then reads the grip and trigger action values to animate the hand.
func _process(_delta: float) -> void:
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return

	# Scale the hand mesh with the world scale.
	if XRServer.world_scale != _world_scale:
		_world_scale = XRServer.world_scale
		transform = _transform.scaled(Vector3.ONE * _world_scale)
		emit_signal("hand_scale_changed", _world_scale)

	# Animate the hand mesh with the controller inputs
	var controller : XRController3D = get_parent()
	if controller:
		var grip : float = controller.get_value(grip_action)
		var trigger : float = controller.get_value(trigger_action)

		# Allow overriding of grip and trigger
		if _force_grip >= 0.0: grip = _force_grip
		if _force_trigger >= 0.0: trigger = _force_trigger

		$AnimationTree.set("parameters/Grip/blend_amount", grip)
		$AnimationTree.set("parameters/Trigger/blend_amount", trigger)



# This method verifies the hand has a valid configuration.
func _get_configuration_warning():
	# Check hand for mesh instance
	if not _find_child(self, "MeshInstance3D"):
		return "Hand does not have a MeshInstance3D"

	# Passed basic validation
	return ""


## Find an [XRToolsHand] node.
##
## This function searches from the specified node for an [XRToolsHand] assuming
## the node is a sibling of the hand under an [ARVRController].
static func find_instance(node : Node) -> XRToolsHand:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_controller(node),
		"*",
		"XRToolsHand") as XRToolsHand


## Set the hand material override
func set_hand_material_override(material : Material) -> void:
	hand_material_override = material
	if is_inside_tree():
		_update_hand_material_override()


func _update_hand_material_override() -> void:
	if _hand_mesh:
		_hand_mesh.material_override = hand_material_override


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
