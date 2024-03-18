@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsDesktopControlerHider
extends Node

## XR Tools Controler Hider
##
## This script hides controler if XR is not active.

# Parent controller
@onready var _controller : XRController3D = XRHelpers.get_xr_controller(self)

# XRStart node
@onready var XRStartNode = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,
	"*Staging",
	"XRToolsStaging"),"StartXR","Node")

var pointer_disabler := false
func _ready() -> void:
	if get_parent().has_method("is_xr_class"):
		if get_parent().is_xr_class("XRToolsFunctionPointer"):
			pointer_disabler = true
	if get_parent() is XRToolsFunctionPointer:
		pointer_disabler = true

# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsDesktopControlerHider"

var last_xr_active := true
func _process(delta: float) -> void:
	if Engine.is_editor_hint() or !is_inside_tree():
		return
	if XRStartNode.xr_active==last_xr_active:
		return
	if pointer_disabler:
		get_parent().enabled=XRStartNode.xr_active
	elif is_instance_valid(_controller):
		_controller.visible=XRStartNode.xr_active
	last_xr_active=XRStartNode.xr_active


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check the controller node
	if !XRHelpers.get_xr_controller(self) and !XRTools.find_xr_ancestor(self,"*","XRToolsFunctionPointer"):
		warnings.append("This node must be within a branch of an XRController3D node")

	# Return warnings
	return warnings
