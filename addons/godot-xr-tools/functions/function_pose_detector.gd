@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name XRToolsFunctionPoseDetector
extends XRToolsHandPalmOffset


## XR Tools Function Pose Area
##
## This area works with the XRToolsHandPoseArea to control the pose
## of the VR hands.


# Default pose detector collision mask of 22:pose-area
const DEFAULT_MASK := 0b0000_0000_0010_0000_0000_0000_0000_0000


## Collision mask to detect hand pose areas
@export_flags_3d_physics var collision_mask : int = DEFAULT_MASK: set = set_collision_mask


## Hand to control
var _hand : XRToolsHand


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsFunctionPoseDetector"


# Called when we enter our tree
func _enter_tree():
	super._enter_tree()

	_hand = XRToolsHand.find_instance(self)

	# Connect signals (if controller and hand are valid)
	if _controller and _hand:
		if $SenseArea.area_entered.connect(_on_area_entered):
			push_error("Unable to connect area_entered signal")
		if $SenseArea.area_exited.connect(_on_area_exited):
			push_error("Unable to connect area_exited signal")

	# Update collision mask
	_update_collision_mask()


func _exit_tree():
	# Disconnect signals (if controller and hand are valid)
	if _controller and _hand:
		$SenseArea.area_entered.disconnect(_on_area_entered)
		$SenseArea.area_exited.disconnect(_on_area_exited)

	_hand = null
	super._exit_tree()


# This method verifies the pose area has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super._get_configuration_warnings()

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

	# Get the positional tracker
	var tracker := XRServer.get_tracker(_controller.tracker) as XRPositionalTracker

	# Set the appropriate poses
	if tracker.hand == XRPositionalTracker.TRACKER_HAND_LEFT and pose_area.left_pose:
		_hand.add_pose_override(
				pose_area,
				pose_area.pose_priority,
				pose_area.left_pose)
		# Disable grabpoints in this pose_area
		pose_area.disable_grab_points()
	elif tracker.hand == XRPositionalTracker.TRACKER_HAND_RIGHT and pose_area.right_pose:
		_hand.add_pose_override(
				pose_area,
				pose_area.pose_priority,
				pose_area.right_pose)
		# Disable grabpoints in this pose_area
		pose_area.disable_grab_points()


## Signal handler called when this XRToolsFunctionPoseArea leaves an area
func _on_area_exited(area : Area3D) -> void:
	# Ignore if the area is not a hand-pose area
	var pose_area := area as XRToolsHandPoseArea
	if !pose_area:
		return

	# Remove any overrides set from this hand-pose area
	_hand.remove_pose_override(pose_area)

	# Enable previously disabled grabpoints
	pose_area.enable_grab_points()
