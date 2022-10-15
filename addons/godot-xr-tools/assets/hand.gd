class_name XRToolsHand
extends Node3D
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")


## XR Tools Hand Script
##
## This script manages a godot-xr-tools hand. It animates the hand blending
## grip and trigger animations based on controller input. Additionally the 
## hand script detects world-scale changes in the XRServer and re-scales the
## hand appropriately so the hand stays scaled to the physical hand of the
## user.


## Signal emitted when the hand scale changes
signal hand_scale_changed(scale)


## Name of the Grip action in the OpenXR Action Map.
@export var grip_action : String = "grip"

## Name of the Trigger action in the OpenXR Action Map.
@export var trigger_action : String = "trigger"


## World scale - used for scaling hands
var _world_scale : float = 1.0


## Initial hand transform (from controller) - used for scaling hands
@onready var _transform : Transform3D = transform


## This method is called on every frame. It checks for world-scale changes and
## scales itself causing the hand mesh and skeleton to scale appropriately.
## It then reads the grip and trigger action values to animate the hand.
func _process(_delta: float) -> void:
	# Scale the hand mesh with the world scale.
	if XRServer.world_scale != _world_scale:
		_world_scale = XRServer.world_scale
		transform = _transform.scaled(Vector3.ONE * _world_scale)
		emit_signal("hand_scale_changed", _world_scale)

	# Animate the hand mesh with the controller inputs
	var controller : XRController3D = get_parent()
	if controller:
		var grip = controller.get_value(grip_action)
		var trigger = controller.get_value(trigger_action)

		$AnimationTree.set("parameters/Grip/blend_amount", grip)
		$AnimationTree.set("parameters/Trigger/blend_amount", trigger)
