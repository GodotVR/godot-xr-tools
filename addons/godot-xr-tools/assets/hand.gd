class_name XRToolsHand, "res://addons/godot-xr-tools/editor/icons/hand.svg"
extends Spatial


## XR Tools Hand Script
##
## This script manages a godot-xr-tools hand. It animates the hand blending
## grip and trigger animations based on controller input. Additionally the 
## hand script detects world-scale changes in the XRServer and re-scales the
## hand appropriately so the hand stays scaled to the physical hand of the
## user.


## Signal emitted when the hand scale changes
signal hand_scale_changed(scale)


## Override the hand material
export (Material) var hand_material_override setget set_hand_material_override


# Last world scale (for scaling hands)
var _last_world_scale : float = 1.0

## Initial hand transform (from controller) - used for scaling hands
var _transform : Transform

## Hand mesh
var _hand_mesh : MeshInstance


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Save the initial hand transform
	_transform = transform

	# Find the hand mesh and update the hand material
	_hand_mesh = _find_mesh_instance(self)
	_update_hand_material_override()


## This method is called on every frame. It checks for world-scale changes and
## scales itself causing the hand mesh and skeleton to scale appropriately.
## It then reads the grip and trigger action values to animate the hand.
func _process(_delta: float) -> void:
	# Scale the hand mesh with the world scale. This is required for OpenXR plugin
	# 1.3.0 and later where the plugin no-longer scales the controllers with
	# world_scale
	if ARVRServer.world_scale != _last_world_scale:
		_last_world_scale = ARVRServer.world_scale
		transform = _transform.scaled(Vector3.ONE * _last_world_scale)
		emit_signal("hand_scale_changed", _last_world_scale)

	# Animate the hand mesh with the controller inputs
	var controller : ARVRController = get_parent()
	if controller:
		var grip = controller.get_joystick_axis(JOY_VR_ANALOG_GRIP)
		var trigger = controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)

		# Uncomment for workaround for bug in OpenXR plugin 1.1.1 and earlier giving values from -1.0 to 1.0
		# note that when controller are not being tracking yet this will result in a value of 0.5
		# grip = (grip + 1.0) * 0.5
		# trigger = (trigger + 1.0) * 0.5

		$AnimationTree.set("parameters/Grip/blend_amount", grip)
		$AnimationTree.set("parameters/Trigger/blend_amount", trigger)

		# var grip_state = controller.is_button_pressed(JOY_VR_GRIP)
		# print("Pressed: " + str(grip_state))


## Set the hand material override
func set_hand_material_override(material : Material) -> void:
	hand_material_override = material
	if is_inside_tree():
		_update_hand_material_override()


func _update_hand_material_override() -> void:
	if _hand_mesh:
		_hand_mesh.material_override = hand_material_override


func _find_mesh_instance(node : Node) -> MeshInstance:
	# Test if the node is a mesh
	var mesh := node as MeshInstance
	if mesh:
		return mesh

	# Check all children
	for i in node.get_child_count():
		mesh = _find_mesh_instance(node.get_child(i))
		if mesh:
			return mesh

	# Could not find mesh
	return null
