@tool
class_name XRToolsHandAimOffset
extends Node3D

## Automatically adjusts its position, to the aim position (within limits).

## Hand offset to apply based on our controller pose. Use [member auto]
## if you're using the default [member aim_pose] or [member grip_pose] poses.
@export_enum("auto", "aim", "grip", "palm", "disable") var hand_offset_mode: int = 0:
	set(value):
		hand_offset_mode = value
		notify_property_list_changed()
		if is_inside_tree():
			_update_transform()


# Controller
var _controller: XRController3D

# Keeps track of our tracker and pose
var _controller_tracker_and_pose := ""

# Node that we apply our transform on
var _apply_to: Node3D

# Additional transform to apply
var _base_transform: Transform3D = Transform3D()


# When we're added to the tree
func _enter_tree() -> void:
	if not _apply_to:
		_apply_to = self

	_controller = XRHelpers.get_xr_controller(self)

	_update_transform()


func _process(_delta: float) -> void:
	# If we have a controller, make sure our hand transform is updated when needed.
	if _controller:
		var tracker_and_pose: String = _controller.tracker + "." + _controller.pose
		if _controller_tracker_and_pose != tracker_and_pose:
			_controller_tracker_and_pose = tracker_and_pose
			if hand_offset_mode == 0:
				_update_transform()


# When we exit the tree
func _exit_tree() -> void:
	if _controller:
		_controller = null


# Verifies the hand has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check for XR Controller
	var controller := XRHelpers.get_xr_controller(self)
	if not controller:
		warnings.append("Hand should descent from an XRController3D node")

	return warnings


# Checks property config
func _validate_property(property: Dictionary[String, Variant]) -> void:
	if hand_offset_mode != 4 and (
			property.name == "position"
			or property.name == "rotation"
			or property.name == "scale"
			or property.name == "rotation_edit_mode"
			or property.name == "rotation_order"
	):
		# We control these, don't let the user set them.
		property.usage = PROPERTY_USAGE_NONE


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsHandAimOffset"


## Sets the node we apply our transform to
## Must be set before [method _enter_tree] is called for the first time.
func set_apply_to(node: Node3D) -> void:
	_apply_to = node


## Sets a base transform to apply
func set_base_transform(base_transform: Transform3D) -> void:
	_base_transform = base_transform
	if is_inside_tree():
		_update_transform()


# Updates our transform so we are positioned on our aim pose
func _update_transform() -> void:
	if _apply_to and hand_offset_mode != 4:
		_apply_to.transform = XRTools.get_aim_offset(
				hand_offset_mode,
				_controller,
		) * _base_transform
