class_name XRToolsHand
extends Spatial


##
## XR Hand Script
##
## @desc:
##     This script manages a godot-xr-tools hand. It animates the hand blending
##     grip and trigger animations based on controller input.
##
##     Additionally the hand script detects world-scale changes in the ARVRServer
##     and re-scales the hand appropriately so the hand stays scaled to the
##     physical hand of the user.
##


# Signal emitted when the hand scale changes
signal hand_scale_changed(scale)


# Last world scale (for scaling hands)
var _last_world_scale := 1.0


# Capture the initial transform
onready var _transform := transform


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
