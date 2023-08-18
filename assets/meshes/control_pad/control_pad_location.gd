@tool
class_name ControlPadLocation
extends Node3D


# Initial transform
var _transform : Transform3D


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "ControlPadLocation"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Capture initial transform
	_transform = transform

	# Subscribe to world scaling events
	var hand := XRToolsHand.find_instance(self)
	if hand:
		hand.hand_scale_changed.connect(_on_hand_scale_changed)


# Handle world scale changing
func _on_hand_scale_changed(scale : float) -> void:
	# Scale ourselves (and our children)
	transform = _transform.scaled(Vector3.ONE * scale)


## Find a ControlPadLocation related to the specified node
static func find_instance(node : Node) -> ControlPadLocation:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_controller(node),
		"*",
		"ControlPadLocation") as ControlPadLocation


## Find the left ControlPadLocation related to the specified node
static func find_left(node : Node) -> ControlPadLocation:
	return XRTools.find_xr_child(
		XRHelpers.get_left_controller(node),
		"*",
		"ControlPadLocation") as ControlPadLocation


## Find the right ControlPadLocation related to the specified node
static func find_right(node : Node) -> ControlPadLocation:
	return XRTools.find_xr_child(
		XRHelpers.get_right_controller(node),
		"*",
		"ControlPadLocation") as ControlPadLocation
