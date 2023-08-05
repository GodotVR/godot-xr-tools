extends TabContainer


## Signal emitted when the control pad hand is switched
signal switch_hand(hand)

## Signal emitted when requested to go to the main scene
signal main_scene


var _tween : Tween

var _player_body : XRToolsPlayerBody


# Called when the node enters the scene tree for the first time.
func _ready():
	# Apply initial scale
	$Body/VBoxContainer/Scale/BodyScaleSlider.value = XRServer.world_scale

	# Find the player body
	_player_body = XRToolsPlayerBody.find_instance(self)


# Called to refresh the display
func _on_refresh_timer_timeout():
	if _player_body and $Body.visible:
		var pos := _player_body.global_position
		var vel := _player_body.velocity
		var pos_str := "%8.3f, %8.3f, %8.3f" % [pos.x, pos.y, pos.z]
		var vel_str := "%8.3f, %8.3f, %8.3f" % [vel.x, vel.y, vel.z]
		$Body/VBoxContainer/Position/Value.text = pos_str
		$Body/VBoxContainer/Velocity/Value.text = vel_str


# Handle user changing the body scale slider
func _on_body_scale_slider_value_changed(value : float) -> void:
	# Kill any current tween
	if _tween:
		_tween.kill()
		
	# Tween the world scale over the next 1/2 second
	_tween = get_tree().create_tween()
	_tween.tween_method(
		_set_world_scale,
		XRServer.world_scale,
		value,
		0.5)


# Handle user selecting the left panel position
func _on_panel_left_pressed():
	switch_hand.emit("LEFT")


# Handle user selecting the right panel position
func _on_panel_right_pressed():
	switch_hand.emit("RIGHT")


# Handle user selecting main scene
func _on_main_scene_pressed():
	main_scene.emit()


# Called by the tweening to change the world scale
func _set_world_scale(scale : float) -> void:
	XRServer.world_scale = scale

