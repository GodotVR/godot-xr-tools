extends Spatial

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
