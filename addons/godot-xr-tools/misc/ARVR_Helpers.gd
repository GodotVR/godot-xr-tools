tool
class_name ARVRHelpers


##
## ARVR Helper Rountines
##
## @desc:
##     This script contains static functions to help find ARVR player nodes.
##
##     As these functions are static, the caller must pass in a node located
##     somewhere under the players ARVROrigin.
##


## Find the ARVR Origin from a player node and an optional path
static func get_arvr_origin(node: Node, var path: NodePath = "") -> ARVROrigin:
	var origin: ARVROrigin

	# Try using the node path first
	if path:
		origin = node.get_node(path) as ARVROrigin
		if origin:
			return origin

	# Walk up the tree from the provided node looking for the origin
	var current = node
	while current:
		origin = current as ARVROrigin
		if origin:
			return origin
		current = current.get_parent()

	# Could not find origin
	return null

## Find the ARVR Camera from a player node and an optional path
static func get_arvr_camera(node: Node, var path: NodePath = "") -> ARVRCamera:
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
	for child in origin.get_children():
		camera = child as ARVRCamera
		if camera:
			return camera
	
	# Could not find camera
	return null

## Find the Left Hand Controller from a player node and an optional path
static func get_left_controller(node: Node, var path: NodePath = "") -> ARVRController:
	return _get_controller(node, "LeftHandController", 1, path)

## Find the Right Hand Controller from a player node and an optional path
static func get_right_controller(node: Node, var path: NodePath = "") -> ARVRController:
	return _get_controller(node, "RightHandController", 2, path)

## Find a controller given some search parameters
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
