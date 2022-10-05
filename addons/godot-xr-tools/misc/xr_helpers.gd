@tool
class_name XRHelpers


##
## XR Helper Rountines
##
## @desc:
##     This script contains static functions to help find XR player nodes.
##
##     As these functions are static, the caller must pass in a node located
##     somewhere under the players XROrigin3D.
##


## Find the XROrigin3D from a player node and an optional path
static func get_xr_origin(node: Node, path: NodePath = NodePath()) -> XROrigin3D:
	var origin: XROrigin3D

	# Try using the node path first
	if path:
		origin = node.get_node(path) as XROrigin3D
		if origin:
			return origin

	# Walk up the tree from the provided node looking for the origin
	var current = node
	while current:
		origin = current as XROrigin3D
		if origin:
			return origin
		current = current.get_parent()

	# Could not find origin
	return null

## Find the XRCamera3D from a player node and an optional path
static func get_xr_camera(node: Node, path: NodePath = NodePath()) -> XRCamera3D:
	var camera: XRCamera3D

	# Try using the node path first
	if path:
		camera = node.get_node(path) as XRCamera3D
		if camera:
			return camera

	# Get the origin
	var origin := get_xr_origin(node)
	if !origin:
		return null

	# Attempt to get by the default name
	camera = origin.get_node_or_null("Camera") as XRCamera3D
	if camera:
		return camera

	# Search all children of the origin for the camera
	for child in origin.get_children():
		camera = child as XRCamera3D
		if camera:
			return camera

	# Could not find camera
	return null

## Find the Left Hand Controller from a player node and an optional path
static func get_left_controller(node: Node, path: NodePath = NodePath()) -> XRController3D:
	return _get_controller(node, "LeftHandController", "left_hand", path)

## Find the Right Hand Controller from a player node and an optional path
static func get_right_controller(node: Node, path: NodePath = NodePath()) -> XRController3D:
	return _get_controller(node, "RightHandController", "right_hand", path)

## Find a controller given some search parameters
static func _get_controller(node: Node, default_name: String, tracker: String, path: NodePath) -> XRController3D:
	var controller: XRController3D
	
	# Try using the node path first
	if path:
		controller = node.get_node(path) as XRController3D
		if controller:
			return controller

	# Get the origin
	var origin := get_xr_origin(node)
	if !origin:
		return null

	# Attempt to get by the default name
	controller = origin.get_node_or_null(default_name) as XRController3D
	if controller:
		return controller

	# Search all children of the origin for the controller
	for child in origin.get_children():
		controller = child as XRController3D
		if controller and controller.tracker == tracker:
			return controller

	# Could not find the controller
	return null
