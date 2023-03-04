@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name XRToolsHandPoseSettings
extends Resource


## XR Tools Hand Pose Settings Resource
##
## This resource defines the settings for hand poses such as the poses for
## hand-open and hand-closed.


## Hand-open pose
@export var open_pose : Animation

## Hand-closed pose
@export var closed_pose : Animation
