extends XRToolsPickable



# Current controller holding this object
var _current_controller : XRController3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)


# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	# Listen for button events on the associated controller
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.button_pressed.connect(_on_controller_button_pressed)


# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# Unsubscribe to controller button events when dropped
	if _current_controller:
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller = null


# Called when a controller button is pressed
func _on_controller_button_pressed(button : String):
	# Skip if not pose-toggle button
	if button != "by_button":
		return

	# Switch the grab point
	var active_grab_point := get_active_grab_point()
	if active_grab_point == $GrabPointHandLeft:
		switch_active_grab_point($GrabPointGripLeft)
	elif active_grab_point == $GrabPointHandRight:
		switch_active_grab_point($GrabPointGripRight)
	elif active_grab_point == $GrabPointGripLeft:
		switch_active_grab_point($GrabPointHandLeft)
	elif active_grab_point == $GrabPointGripRight:
		switch_active_grab_point($GrabPointHandRight)
