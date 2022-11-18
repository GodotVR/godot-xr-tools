class_name XRToolsFunctionPoseArea, "res://addons/godot-xr-tools/editor/icons/hand.svg"
extends Spatial


## XR Tools Function Pose Area
##
## This area works with the XRToolsHandPoseArea to control the pose
## of the VR hands.


## Collision mask to detect hand pose areas
export (int, LAYERS_3D_PHYSICS) var collision_mask : int = 1 << 21 setget set_collision_mask


## Hand controller
var _controller : ARVRController

## Hand to control
var _hand : XRToolsHand


# Called when the node enters the scene tree for the first time.
func _ready():
	# Find controller and hand
	_controller = get_parent() as ARVRController
	_hand = _find_hand()

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
	# Verify hand can be found
	if !_find_hand():
		return "Node must be a child of an ARVRController with a hand"

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


func _find_hand() -> XRToolsHand:
	# Get the parent
	var parent := get_parent()
	if !parent:
		return null

	# Make sure it's a controller
	var controller := parent as ARVRController
	if !controller:
		return null

	# Look for hands under the controller
	for child in controller.get_children():
		var hand := child as XRToolsHand
		if hand:
			return hand
	
	# No hand found
	return null
