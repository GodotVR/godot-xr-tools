tool
class_name XRToolsFunctionPoseDetector, "res://addons/godot-xr-tools/editor/icons/hand.svg"
extends Spatial


## XR Tools Function Pose Area
##
## This area works with the XRToolsHandPoseArea to control the pose
## of the VR hands.


# Default pose detector collision mask of 22:pose-area
const DEFAULT_MASK := 0b0000_0000_0010_0000_0000_0000_0000_0000


## Collision mask to detect hand pose areas
export (int, LAYERS_3D_PHYSICS) var collision_mask : int = DEFAULT_MASK setget set_collision_mask


## Hand controller
onready var _controller := ARVRHelpers.get_arvr_controller(self)

## Hand to control
onready var _hand := XRToolsHand.find_instance(self)


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsFunctionPoseDetector" or .is_class(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect signals (if controller and hand are valid)
	if _controller and _hand:
		if $SenseArea.connect("area_entered", self, "_on_area_entered"):
			push_error("Unable to connect area_entered signal")
		if $SenseArea.connect("area_exited", self, "_on_area_exited"):
			push_error("Unable to connect area_exited signal")

	# Update collision mask
	_update_collision_mask()


# This method verifies the pose area has a valid configuration.
func _get_configuration_warning():
	if !ARVRHelpers.get_arvr_controller(self):
		return "Node must be within a branch of an ARVRController node"

	# Verify hand can be found
	if !XRToolsHand.find_instance(self):
		return "Node must be a within a branch of an ARVRController node with a hand"

	# Pass basic validation
	return ""


func set_collision_mask(mask : int) -> void:
	collision_mask = mask
	if is_inside_tree():
		_update_collision_mask()


func _update_collision_mask() -> void:
	$SenseArea.collision_mask = collision_mask


## Signal handler called when this XRToolsFunctionPoseArea enters an area
func _on_area_entered(area : Area) -> void:
	# Igjnore if the area is not a hand-pose area
	var pose_area := area as XRToolsHandPoseArea
	if !pose_area:
		return

	# Set the appropriate poses
	if _controller.controller_id == 1 and pose_area.left_pose:
		_hand.add_pose_override(
				pose_area,
				pose_area.pose_priority,
				pose_area.left_pose)
	elif _controller.controller_id == 2 and pose_area.right_pose:
		_hand.add_pose_override(
				pose_area,
				pose_area.pose_priority,
				pose_area.right_pose)


## Signal handler called when this XRToolsFunctionPoseArea leaves an area
func _on_area_exited(area : Area) -> void:
	# Ignore if the area is not a hand-pose area
	var pose_area := area as XRToolsHandPoseArea
	if !pose_area:
		return

	# Remove any overrides set from this hand-pose area
	_hand.remove_pose_override(pose_area)
