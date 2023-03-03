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


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsHandPoseArea"
