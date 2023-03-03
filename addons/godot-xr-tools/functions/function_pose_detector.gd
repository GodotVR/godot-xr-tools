@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name XRToolsFunctionPoseDetector
extends Node3D


## XR Tools Function Pose Area
##
## This area works with the XRToolsHandPoseArea to control the pose
## of the VR hands.


# Default pose detector collision mask of 22:pose-area
const DEFAULT_MASK := 0b0000_0000_0010_0000_0000_0000_0000_0000


## Collision mask to detect hand pose areas
@export_flags_3d_physics var collision_mask : int = DEFAULT_MASK: set = set_collision_mask


## Hand controller
@onready var _controller := XRHelpers.get_xr_controller(self)

## Hand to control
@onready var _hand := XRToolsHand.find_instance(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsFunctionPoseDetector"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect signals (if controller and hand are valid)
	if _controller and _hand:
		if $SenseArea.area_entered.connect(_on_area_entered):
			push_error("Unable to connect area_entered signal")
		if $SenseArea.area_exited.connect(_on_area_exited):
			push_error("Unable to connect area_exited signal")

	# Update collision mask
	_update_collision_mask()


# This method verifies the pose area has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if !XRHelpers.get_xr_controller(self):
		warnings.append("Node must be within a branch of an XRController3D node")

	# Verify hand can be found
	if !XRToolsHand.find_instance(self):
		warnings.append("Node must be a within a branch of an XRController node with a hand")

	# Pass basic validation
	return warnings


func set_collision_mask(mask : int) -> void:
	collision_mask = mask
	if is_inside_tree():
		_update_collision_mask()


func _update_collision_mask() -> void:
	$SenseArea.collision_mask = collision_mask


## Signal handler called when this XRToolsFunctionPoseArea enters an area
func _on_area_entered(area : Area3D) -> void:
	# Igjnore if the area is not a hand-pose area
	var pose_area := area as XRToolsHandPoseArea
	if !pose_area:
		return

	# Set the appropriate poses
	if _controller.tracker == "left_hand" and pose_area.left_pose:
		_hand.add_pose_override(
				pose_area,
				pose_area.pose_priority,
				pose_area.left_pose)
	elif _controller.tracker == "right_hand" and pose_area.right_pose:
		_hand.add_pose_override(
				pose_area,
				pose_area.pose_priority,
				pose_area.right_pose)


## Signal handler called when this XRToolsFunctionPoseArea leaves an area
func _on_area_exited(area : Area3D) -> void:
	# Ignore if the area is not a hand-pose area
	var pose_area := area as XRToolsHandPoseArea
	if !pose_area:
		return

	# Remove any overrides set from this hand-pose area
	_hand.remove_pose_override(pose_area)
