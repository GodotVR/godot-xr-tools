@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name XRToolsHandPoseArea
extends Area3D


## XR Tools Hand Pose Area
##
## This area works with the XRToolsFunctionPoseArea to control the pose
## of the VR hands.


## Priority level for this hand pose area
@export var pose_priority : int

## Left hand pose settings (XRToolsHandPoseSettings)
@export var left_pose : XRToolsHandPoseSettings

## Right hand pose settings (XRToolsHandPoseSettings)
@export var right_pose : XRToolsHandPoseSettings

## Array of grabpoints this hand pose area disables when active
@export var grabpoints : Array[XRToolsGrabPointHand]

# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsHandPoseArea"

# Disables grabpoints
func disable_grab_points():
	for grabpoint in grabpoints:
		grabpoint.enabled = false

# Enables grabpoints
func enable_grab_points():
	for grabpoint in grabpoints:
		grabpoint.enabled = true
