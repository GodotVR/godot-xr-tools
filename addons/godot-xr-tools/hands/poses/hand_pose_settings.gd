@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name XRToolsHandPoseSettings
extends Resource


## XR Tools Hand Pose Settings Resource
##
## This resource defines the settings for hand poses such as the poses for
## hand-open and hand-closed.


## Hand-open pose
@export var open_pose : Animation : set = set_open_pose

## Hand-closed pose
@export var closed_pose : Animation : set = set_closed_pose


# Called when the open pose is changed
func set_open_pose(p_open_pose : Animation) -> void:
	open_pose = p_open_pose
	emit_changed()


# Called when the closed pose is changed
func set_closed_pose(p_closed_pos : Animation) -> void:
	closed_pose = p_closed_pos
	emit_changed()
