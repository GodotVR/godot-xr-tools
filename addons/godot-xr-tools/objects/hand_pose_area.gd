tool
class_name XRToolsHandPoseArea, "res://addons/godot-xr-tools/editor/icons/hand.svg"
extends Area


## XR Tools Hand Pose Area
##
## This area works with the XRToolsFunctionPoseArea to control the pose
## of the VR hands.


## Priority level for this hand pose area
export var pose_priority : int

## Left hand pose settings (XRToolsHandPoseSettings)
export var left_pose : Resource

## Right hand pose settings (XRToolsHandPoseSettings)
export var right_pose : Resource


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsHandPoseArea" or .is_class(name)
