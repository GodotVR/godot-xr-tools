class_name XRToolsHandPoseArea, "res://addons/godot-xr-tools/editor/icons/hand.svg"
extends Area


## XR Tools Hand Pose Area
##
## This area works with the XRToolsFunctionPoseArea to control the pose
## of the VR hands.


## Left open-hand animation pose
export var left_open_hand : Animation

## Left closed-hand animation pose
export var left_closed_hand : Animation

## Right open-hand animation pose
export var right_open_hand : Animation

## Left closed-hand animation pose
export var right_closed_hand : Animation
