@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsDesktopControllerHider
extends Node

## XR Tools Controller Hider
##
## This script hides controller if XR is not active.

var _pointer_disabler := false
var _last_xr_active := true
# XRStart node
@onready var xr_start_node = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,
	"*Staging",
	"XRToolsStaging"),"StartXR","Node")

# Parent controller
@onready var _controller : XRController3D = XRHelpers.get_xr_controller(self)

func _ready() -> void:
	if get_parent().has_method("is_xr_class"):
		if get_parent().is_xr_class("XRToolsFunctionPointer"):
			_pointer_disabler = true
	if get_parent() is XRToolsFunctionPointer:
		_pointer_disabler = true

# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsDesktopControllerHider"

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or !is_inside_tree():
		return
	if xr_start_node.is_xr_active()==_last_xr_active:
		return
	if _pointer_disabler:
		get_parent().enabled=xr_start_node.is_xr_active()
	elif is_instance_valid(_controller):
		_controller.visible=xr_start_node.is_xr_active()
	_last_xr_active=xr_start_node.is_xr_active()


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check the controller node
	if !XRHelpers.get_xr_controller(self) \
		and !XRTools.find_xr_ancestor(self,"*","XRToolsFunctionPointer"):
		warnings.append("This node must be within a branch of an XRController3D node")

	# Return warnings
	return warnings
