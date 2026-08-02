class_name XRTools
extends Node

## Below are helper functions to obtain various project settings that drive
## the default behavior of XR Tools. The project settings themselves are
## registered in plugin.gd.
## Some of these settings can be overridden by the user through user settings.

## Position offset based on controller poses
enum HandOffsetMode {
	HAND_OFFSET_AUTO, ## Determines based on using default poses
	HAND_OFFSET_AIM, ## Our pose is an aim pose
	HAND_OFFSET_GRIP, ## Our pose is a grip pose
	HAND_OFFSET_PALM ## Our pose is a palm pose
}


## Maps interaction profiles to grip rotations.[br][br]
## TODO: we need to complete this with more controllers.
static var grip_rotations: Dictionary[String, float] = {
	"/interaction_profiles/oculus/touch_controller": deg_to_rad(-60.0),
	"/interaction_profiles/facebook/touch_controller_pro": deg_to_rad(-60.0),
	"/interaction_profiles/meta/touch_controller_plus": deg_to_rad(-60.0),
	"/interaction_profiles/bytedance/pico4_controller": deg_to_rad(-40.0),
	"/interaction_profiles/bytedance/pico4s_controller": deg_to_rad(-40.0),
	"/interaction_profiles/bytedance/pico_ultra_controller_bd": deg_to_rad(-40.0),
}


## Gets a transform that offsets the controller pose, so that we're at the aim
## position.[br][br]
##
## [b]Note[/b]: if the aim pose is used, we use that location as is,
## else we try and reproduce the original aim pose location,
## which may be different.
static func get_aim_offset(
		mode: HandOffsetMode,
		xr_controller: XRController3D,
) -> Transform3D:
	var transform := Transform3D()
	var is_left_hand := true
	var profile := ""

	if xr_controller:
		if xr_controller.tracker != "left_hand":
			is_left_hand = false

		var xr_tracker: XRControllerTracker = XRServer.get_tracker(xr_controller.tracker)
		if xr_tracker:
			profile = xr_tracker.profile

		if mode != XRTools.HandOffsetMode.HAND_OFFSET_AUTO:
			pass
		elif xr_controller.pose == "aim":
			mode = XRTools.HandOffsetMode.HAND_OFFSET_AIM
		elif xr_controller.pose == "grip":
			mode = XRTools.HandOffsetMode.HAND_OFFSET_GRIP
		else:
			# Assume we're using a palm pose
			mode = XRTools.HandOffsetMode.HAND_OFFSET_PALM

	match mode:
		XRTools.HandOffsetMode.HAND_OFFSET_AUTO:
			# No controller? keep identity transform
			pass
		XRTools.HandOffsetMode.HAND_OFFSET_AIM:
			# Aim, identity transform is what we want.
			pass
		XRTools.HandOffsetMode.HAND_OFFSET_GRIP:
			# Grip, is rotated 45 degrees to be aligned with controller grip
			# So we reverse the rotation
			transform.basis = Basis(Vector3(1.0, 0.0, 0.0), get_grip_rotation(profile))

			# and offset
			if is_left_hand:
				transform.origin = transform.basis * Vector3(0.02, 0.05, -0.10)
			else:
				transform.origin = transform.basis * Vector3(-0.02, 0.05, -0.10)
		XRTools.HandOffsetMode.HAND_OFFSET_PALM:
			# Just offset
			if is_left_hand:
				transform.origin = Vector3(0.02, 0.05, -0.10)
			else:
				transform.origin = Vector3(-0.02, 0.05, -0.10)
		_:
			# Unsupported
			pass

	return transform


## Gets our default value for enabling snap-turning.
static func get_default_snap_turning() -> bool:
	var default := true

	if ProjectSettings.has_setting("godot_xr_tools/input/default_snap_turning"):
		default = ProjectSettings.get_setting("godot_xr_tools/input/default_snap_turning")

	# default may not be bool, so JIC
	return default == true


## Gets our grip rotation for various controller profiles.[br][br]
## [b]Note[/b]: this is a guestimate, and that (in theory) rotations can vary
## between runtimes.
static func get_grip_rotation(profile: String) -> float:
	# TODO: add in a way for users to override this through a setting.
	if grip_rotations.has(profile):
		return grip_rotations[profile]

	# We return 45 degrees as a default
	return deg_to_rad(-45.0)


## Gets our configured grip threshold.
static func get_grip_threshold() -> float:
	# can return null which is not a float, so don't type this!
	var threshold = 0.7

	if ProjectSettings.has_setting("godot_xr_tools/input/grip_threshold"):
		threshold = ProjectSettings.get_setting("godot_xr_tools/input/grip_threshold")

	if not (threshold >= 0.2 and threshold <= 0.8):
		# out of bounds? reset to default
		threshold = 0.7

	return threshold


## Gets a transform that offsets the controller pose so that we center on the palm
static func get_palm_offset(
		mode: HandOffsetMode,
		xr_controller: XRController3D,
) -> Transform3D:
	var transform := Transform3D()
	var is_left_hand := true
	var profile := ""

	if xr_controller:
		if xr_controller.tracker != "left_hand":
			is_left_hand = false

		var xr_tracker: XRControllerTracker = XRServer.get_tracker(xr_controller.tracker)
		if xr_tracker:
			profile = xr_tracker.profile

		if mode != XRTools.HandOffsetMode.HAND_OFFSET_AUTO:
			pass
		elif xr_controller.pose == "aim":
			mode = XRTools.HandOffsetMode.HAND_OFFSET_AIM
		elif xr_controller.pose == "grip":
			mode = XRTools.HandOffsetMode.HAND_OFFSET_GRIP
		else:
			# Assume we're using a palm pose
			mode = XRTools.HandOffsetMode.HAND_OFFSET_PALM

	match mode:
		XRTools.HandOffsetMode.HAND_OFFSET_AUTO:
			# No controller? keep identity transform
			pass
		XRTools.HandOffsetMode.HAND_OFFSET_AIM:
			# These are our original aim offsets.
			# They are fairly unreliable now for many headsets.
			if is_left_hand:
				transform.origin = Vector3(-0.02, -0.05, 0.10)
			else:
				transform.origin = Vector3(0.02, -0.05, 0.10)
		XRTools.HandOffsetMode.HAND_OFFSET_GRIP:
			# Grip, is rotated 45 degrees to be aligned with controller grip
			# So we reverse the rotation
			transform.basis = Basis(Vector3(1.0, 0.0, 0.0), get_grip_rotation(profile))

			# Todo, we should offset.origin.x depending on the hand,
			# as our grip pose is centered on the controller.
			# But we need some sort of average, or possibly start maintaining
			# a matrix of adjustments per interaction profile, which would suck.
		XRTools.HandOffsetMode.HAND_OFFSET_PALM:
			# Palm, identity transform does fine.
			# Our palm pose should be in the correct location.
			pass
		_:
			# Unsupported
			pass

	return transform


## Gets our player's standard height.
static func get_player_standard_height() -> float:
	var standard_height := 1.85

	if ProjectSettings.has_setting("godot_xr_tools/player/standard_height"):
		standard_height = ProjectSettings.get_setting("godot_xr_tools/player/standard_height")

	if not (standard_height >= 1.0 and standard_height <= 2.5):
		# out of bounds? reset to default
		standard_height = 1.85

	return standard_height


## Gets our snap-turning deadzone.
static func get_snap_turning_deadzone() -> float:
	# can return null which is not a float, so don't type this!
	var deadzone = 0.25

	if ProjectSettings.has_setting("godot_xr_tools/input/snap_turning_deadzone"):
		deadzone = ProjectSettings.get_setting("godot_xr_tools/input/snap_turning_deadzone")

	if not (deadzone >= 0.0 and deadzone <= 0.5):
		# out of bounds? reset to default
		deadzone = 0.25

	return deadzone


## Get our x-axis dead zone.
static func get_x_axis_dead_zone() -> float:
	# can return null which is not a float, so don't type this!
	var deadzone = 0.2

	if ProjectSettings.has_setting("godot_xr_tools/input/x_axis_dead_zone"):
		deadzone = ProjectSettings.get_setting("godot_xr_tools/input/x_axis_dead_zone")

	if not (deadzone >= 0.0 and deadzone <= 0.5):
		# out of bounds? reset to default
		deadzone = 0.2

	return deadzone


## Gets our y-axis deadzone.
static func get_y_axis_dead_zone() -> float:
	# can return null which is not a float, so don't type this!
	var deadzone = 0.1

	if ProjectSettings.has_setting("godot_xr_tools/input/y_axis_dead_zone"):
		deadzone = ProjectSettings.get_setting("godot_xr_tools/input/y_axis_dead_zone")

	if not (deadzone >= 0.0 and deadzone <= 0.5):
		# out of bounds? reset to default
		deadzone = 0.1

	return deadzone


## Finds the first ancestor of the specified node matching the given criteria.
##[br][br]
## [param pattern] specifies the match pattern to check against the node name.
## Use "*" to match anything.
##[br][br]
## [param type] specifies the type of node to find. Use "" to match any type.
static func find_xr_ancestor(
		node: Node,
		pattern: String,
		type: String = "",
) -> Node:
	# Loop finding ancestor
	while node:
		# If node matches filter then break
		if (
				node.name.match(pattern)
				and (type == "" or is_xr_class(node, type))
		):
			break

		# Advance to parent
		node = node.get_parent()

	# Return found node (or null)
	return node


## Finds the first child of the specified node matching the given criteria.
##[br][br]
## [param pattern] specifies the match pattern to check against the node name.
## Use "*" to match anything.
##[br][br]
## [param type] specifies the type of node to find. Use "" to match any type.
##[br][br]
## [param recursive] specifies whether the search deeply though all child nodes,
## or whether to only check the immediate children.
##[br][br]
## [param owned] specifies whether the node must be owned.
static func find_xr_child(
		node: Node,
		pattern: String,
		type: String = "",
		recursive: bool = true,
		owned: bool = true,
) -> Node:
	# Find the child
	if node:
		return _find_xr_child(node, pattern, type, recursive, owned)

	# Invalid node
	return null


## Finds all children of the specified node matching the given criteria. This
## function can be slow and [method find_child] is faster if only one child is
## needed.
##[br][br]
## [param pattern] specifies the match pattern to check against the node name.
## Use "*" to match anything.
##[br][br]
## [param type] specifies the type of node to find. Use "" to match any type.
##[br][br]
## [param recursive] specifies whether the search deeply though all child
## nodes, or whether to only check the immediate children.
##[br][br]
## [param owned] specifies whether the node must be owned.
static func find_xr_children(
		node: Node,
		pattern: String,
		type: String = "",
		recursive: bool = true,
		owned: bool = true,
) -> Array[Node]:
	# Find the children
	var found: Array[Node] = []
	if node:
		_find_xr_children(found, node, pattern, type, recursive, owned)
	return found


## Tests if a given node is of the specified class
static func is_xr_class(node: Node, type: String) -> bool:
	if node.has_method("is_xr_class"):
		if node.is_xr_class(type):
			return true

	return node.is_class(type)


## Sets our default value for enabling snap-turning.
static func set_default_snap_turning(p_default: bool) -> void:
	ProjectSettings.set_setting("godot_xr_tools/input/default_snap_turning", p_default)


## Sets our configured grip threshold.
static func set_grip_threshold(p_threshold: float) -> void:
	if not (p_threshold >= 0.2 and p_threshold <= 0.8):
		print("Threshold out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/input/grip_threshold", p_threshold)


## Sets our player's standard height.
static func set_player_standard_height(p_height: float) -> void:
	if not (p_height >= 1.0 and p_height <= 2.5):
		print("Standard height out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/player/standard_height", p_height)


## Sets our snap-turning deadzone.
static func set_snap_turning_deadzone(p_deadzone: float) -> void:
	if not (p_deadzone >= 0.0 and p_deadzone <= 0.5):
		print("Deadzone out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/input/snap_turning_deadzone", p_deadzone)


## Sets our x-axis deadzone.
static func set_x_axis_dead_zone(p_deadzone: float) -> void:
	if not (p_deadzone >= 0.0 and p_deadzone <= 0.5):
		print("Deadzone out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/input/x_axis_dead_zone", p_deadzone)


## Sets our y-axis deadzone.
static func set_y_axis_dead_zone(p_deadzone: float) -> void:
	if not (p_deadzone >= 0.0 and p_deadzone <= 0.5):
		print("Deadzone out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/input/y_axis_dead_zone", p_deadzone)


# Recursively searches for the first child of a Node that matches a pattern.
static func _find_xr_child(
		node: Node,
		pattern: String,
		type: String,
		recursive: bool,
		owned: bool,
) -> Node:
	# Iterate over all children
	for i: int in node.get_child_count():
		# Get the child
		var child := node.get_child(i)

		# If child matches filter, then return it
		if (
				child.name.match(pattern)
				and (type == "" or is_xr_class(child, type))
				and (not owned or child.owner)
		):
			return child

		# If recursive is enabled then descend into children
		if recursive:
			var found := _find_xr_child(child, pattern, type, recursive, owned)
			if found:
				return found

	# Not found
	return null


# Recursively finds children of a Node that match a pattern.
static func _find_xr_children(
		found: Array[Node],
		node: Node,
		pattern: String,
		type: String,
		recursive: bool,
		owned: bool,
) -> void:
	# Iterate over all children
	for i: int in node.get_child_count():
		# Get the child
		var child := node.get_child(i)

		# If child matches filter, then add it to the array
		if (
				child.name.match(pattern)
				and (type == "" or is_xr_class(child, type))
				and (not owned or child.owner)
		):
			found.push_back(child)

		# If recursive is enabled then descend into children
		if recursive:
			_find_xr_children(found, child, pattern, type, recursive, owned)
