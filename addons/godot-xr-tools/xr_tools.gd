class_name XRTools
extends Node

# This class contains global definitions for our XRTools library

# enum our axis
enum Axis {
	VR_PRIMARY_X_AXIS = 0,
	VR_PRIMARY_Y_AXIS = 1,
	VR_SECONDARY_X_AXIS = 6,
	VR_SECONDARY_Y_AXIS = 7,
	VR_TRIGGER_AXIS = 2,
	VR_GRIP_AXIS = 4
}


# enum our buttons
enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15,
	VR_ACTION = 255 ## Only supported in function pointer, should solve that differently!!
}


static func get_grip_threshold() -> float:
	# can return null which is not a float, so don't type this!
	var threshold = 0.7

	if ProjectSettings.has_setting("godot_xr_tools/input/grip_threshold"):
		threshold = ProjectSettings.get_setting("godot_xr_tools/input/grip_threshold")

	if !(threshold >= 0.2 and threshold <= 0.8):
		# out of bounds? reset to default
		threshold = 0.7

	return threshold

static func set_grip_threshold(p_threshold : float) -> void:
	if !(p_threshold >= 0.2 and p_threshold <= 0.8):
		print("Threshold out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/input/grip_threshold", p_threshold)


static func get_snap_turning_deadzone() -> float:
	# can return null which is not a float, so don't type this!
	var deadzone = 0.25

	if ProjectSettings.has_setting("godot_xr_tools/input/snap_turning_deadzone"):
		deadzone = ProjectSettings.get_setting("godot_xr_tools/input/snap_turning_deadzone")

	if !(deadzone >= 0.0 and deadzone <= 0.5):
		# out of bounds? reset to default
		deadzone = 0.25

	return deadzone

static func set_snap_turning_deadzone(p_deadzone : float) -> void:
	if !(p_deadzone >= 0.0 and p_deadzone <= 0.5):
		print("Deadzone out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/input/snap_turning_deadzone", p_deadzone)


static func get_default_snap_turning() -> bool:
	var default = true

	if ProjectSettings.has_setting("godot_xr_tools/input/default_snap_turning"):
		default = ProjectSettings.get_setting("godot_xr_tools/input/default_snap_turning")

	# default may not be bool, so JIC
	return default == true

static func set_default_snap_turning(p_default : bool) -> void:
	ProjectSettings.set_setting("godot_xr_tools/input/default_snap_turning", p_default)


static func get_player_standard_height() -> float:
	var standard_height = 1.85

	if ProjectSettings.has_setting("godot_xr_tools/player/standard_height"):
		standard_height = ProjectSettings.get_setting("godot_xr_tools/player/standard_height")

	if !(standard_height >= 1.0 and standard_height <= 2.5):
		# out of bounds? reset to default
		standard_height = 1.85

	return standard_height

static func set_player_standard_height(p_height : float) -> void:
	if !(p_height >= 1.0 and p_height <= 2.5):
		print("Standard height out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/player/standard_height", p_height)

## Find all children of the specified node matching the given criteria
##
## This function returns an array containing all children of the specified
## node matching the given criteria. This function can be slow and find_child
## is faster if only one child is needed.
##
## The pattern argument specifies the match pattern to check against the
## node name. Use "*" to match anything.
##
## The type argument specifies the type of node to find. Use "" to match any
## type.
##
## The recursive argument specifies whether the search deeply though all child
## nodes, or whether to only check the immediate children.
##
## The owned argument specifies whether the node must be owned.
static func find_children(
		node : Node,
		pattern : String,
		type : String = "",
		recursive : bool = true,
		owned : bool = true) -> Array:
	# Find the children
	var found := []
	if node:
		_find_children(found, node, pattern, type, recursive, owned)
	return found

## Find a child of the specified node matching the given criteria
##
## This function finds the first child of the specified node matching the given
## criteria.
##
## The pattern argument specifies the match pattern to check against the
## node name. Use "*" to match anything.
##
## The type argument specifies the type of node to find. Use "" to match any
## type.
##
## The recursive argument specifies whether the search deeply though all child
## nodes, or whether to only check the immediate children.
##
## The owned argument specifies whether the node must be owned.
static func find_child(
		node : Node,
		pattern : String,
		type : String = "",
		recursive : bool = true,
		owned : bool = true) -> Node:
	# Find the child
	if node:
		return _find_child(node, pattern, type, recursive, owned)

	# Invalid node
	return null

## Find an ancestor of the specified node matching the given criteria
##
## This function finds the first ancestor of the specified node matching the
## given criteria.
##
## The pattern argument specifies the match pattern to check against the
## node name. Use "*" to match anything.
##
## The type argument specifies the type of node to find. Use "" to match any
## type.
static func find_ancestor(
		node : Node,
		pattern : String,
		type : String = "") -> Node:
	# Loop finding ancestor
	while node:
		# If node matches filter then break
		if (node.name.match(pattern) and
			(type == "" or node.is_class(type))):
			break

		# Advance to parent
		node = node.get_parent()

	# Return found node (or null)
	return node

# Recursive helper function for find_children.
static func _find_children(
		found : Array,
		node : Node,
		pattern : String,
		type : String,
		recursive : bool,
		owned : bool) -> void:
	# Iterate over all children
	for i in node.get_child_count():
		# Get the child
		var child := node.get_child(i)

		# If child matches filter then add it to the array
		if (child.name.match(pattern) and
			(type == "" or child.is_class(type)) and
			(not owned or child.owner)):
			found.push_back(child)

		# If recursive is enabled then descend into children
		if recursive:
			_find_children(found, child, pattern, type, recursive, owned)

# Recursive helper functiomn for find_child
static func _find_child(
		node : Node,
		pattern : String,
		type : String,
		recursive : bool,
		owned : bool) -> Node:
	# Iterate over all children
	for i in node.get_child_count():
		# Get the child
		var child := node.get_child(i)

		# If child matches filter then return it
		if (child.name.match(pattern) and
			(type == "" or child.is_class(type)) and
			(not owned or child.owner)):
			return child

		# If recursive is enabled then descend into children
		if recursive:
			var found := _find_child(child, pattern, type, recursive, owned)
			if found:
				return found

	# Not found
	return null
