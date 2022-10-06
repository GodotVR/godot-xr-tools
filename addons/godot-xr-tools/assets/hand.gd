class_name XRToolsHand
extends Node3D
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")


##
## XR Hand Script
##
## @desc:
##     This script manages a godot-xr-tools hand. It animates the hand blending
##     grip and trigger animations based on controller input.
##
##     Additionally the hand script detects world-scale changes in the XRServer
##     and re-scales the hand appropriately so the hand stays scaled to the
##     physical hand of the user.
##


# Signal emitted when the hand scale changes
signal hand_scale_changed(scale)


## Grip action
@export var grip_action = "grip"

## Trigger action
@export var trigger_action = "trigger"


# Last world scale (for scaling hands)
var _last_world_scale : float = 1.0


# Capture the initial transform
@onready var _transform : Transform3D = transform


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return

	# Scale the hand mesh with the world scale.
	if XRServer.world_scale != _last_world_scale:
		_last_world_scale = XRServer.world_scale
		transform = _transform.scaled(Vector3.ONE * _last_world_scale)
		emit_signal("hand_scale_changed", _last_world_scale)

	# Animate the hand mesh with the controller inputs
	var controller : XRController3D = get_parent()
	if controller:
		var grip = controller.get_value(grip_action)
		var trigger = controller.get_value(trigger_action)

		$AnimationTree.set("parameters/Grip/blend_amount", grip)
		$AnimationTree.set("parameters/Trigger/blend_amount", trigger)

		# var grip_state = controller.is_button_pressed(grip_button_action)
		# print("Pressed: " + str(grip_state))
