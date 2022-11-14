tool
class_name ARVRHelpers


## XR Tools Helper Rountines
##
## This script contains static functions to help find ARVR player nodes.
##
## As these functions are static, the caller must pass in a node located
## somewhere under the players [ARVROrigin].


## Find the ARVR Origin from a player node and an optional path
static func get_arvr_origin(node: Node, path: NodePath = NodePath("")) -> ARVROrigin:
	var origin: ARVROrigin

	# Try using the node path first
	if path:
		origin = node.get_node(path) as ARVROrigin
		if origin:
			return origin

	# Walk up the tree from the provided node looking for the origin
	origin = find_ancestor(node, "*", "ARVROrigin")
	if origin:
		return origin

	# We check our children but only one level
	origin = find_child(node, "*", "ARVROrigin", false)
	if origin:
		return origin

	# Could not find origin
	return null

## Find the ARVR Camera from a player node and an optional path
static func get_arvr_camera(node: Node, path: NodePath = NodePath("")) -> ARVRCamera:
	var camera: ARVRCamera

	# Try using the node path first
	if path:
		camera = node.get_node(path) as ARVRCamera
		if camera:
			return camera

	# Get the origin
	var origin := get_arvr_origin(node)
	if !origin:
		return null

	# Attempt to get by the default name
	camera = origin.get_node_or_null("ARVRCamera") as ARVRCamera
	if camera:
		return camera

	# Search all children of the origin for the camera
	camera = find_child(origin, "*", "ARVRCamera", false)
	if camera:
		return camera

	# Could not find camera
	return null

## Find the Left Hand Controller from a player node and an optional path
static func get_left_controller(node: Node, path: NodePath = NodePath("")) -> ARVRController:
	return _get_controller(node, "LeftHandController", 1, path)

## Find the Right Hand Controller from a player node and an optional path
static func get_right_controller(node: Node, path: NodePath = NodePath("")) -> ARVRController:
	return _get_controller(node, "RightHandController", 2, path)

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
		if (node.name.match(pattern) and (type == "" or node.is_class(type))):
			break

		# Advance to parent
		node = node.get_parent()

	# Return found node (or null)
	return node


# Find a controller given some search parameters
static func _get_controller(var node: Node, var default_name: String, var id: int, var path: NodePath) -> ARVRController:
	var controller: ARVRController

	# Try using the node path first
	if path:
		controller = node.get_node(path) as ARVRController
		if controller:
			return controller

	# Get the origin
	var origin := get_arvr_origin(node)
	if !origin:
		return null

	# Attempt to get by the default name
	controller = origin.get_node_or_null(default_name) as ARVRController
	if controller:
		return controller

	# Search all children of the origin for the controller
	for child in origin.get_children():
		controller = child as ARVRController
		if controller and controller.controller_id == id:
			return controller

	# Could not find the controller
	return null

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
			var found := _find_child(node, pattern, type, recursive, owned)
			if found:
				return found
	
	# Not found
	return null
