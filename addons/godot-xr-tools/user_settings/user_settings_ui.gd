extends TabContainer

signal player_height_changed(new_height: float)

@onready var snap_turning_button: CheckBox = $Input/InputVBox/SnapTurning/SnapTurningCB
@onready var haptics_scale_slider: HSlider = $Input/InputVBox/HapticsScale/HapticsScaleSlider
@onready var y_deadzone_slider: HSlider = $Input/InputVBox/yAxisDeadZone/yAxisDeadZoneSlider
@onready var x_deadzone_slider: HSlider = $Input/InputVBox/xAxisDeadZone/xAxisDeadZoneSlider
@onready var player_height_slider: HSlider = $Player/PlayerVBox/PlayerHeight/PlayerHeightSlider
@onready var webxr_primary_button: OptionButton = $WebXR/WebXRVBox/WebXR/WebXRPrimary


# When the node enters the scene tree for the first time.
func _ready() -> void:
	var webxr_interface := XRServer.find_interface("WebXR")
	set_tab_hidden(2, webxr_interface == null)

	if XRToolsUserSettings:
		_update()
	else:
		$Save/Button.disabled = true


func _on_haptics_scale_slider_value_changed(value: float) -> void:
	XRToolsUserSettings.haptics_scale = value


func _on_PlayerHeightSlider_drag_ended(_value_changed: bool) -> void:
	XRToolsUserSettings.player_height = player_height_slider.value
	player_height_changed.emit(XRToolsUserSettings.player_height)


func _on_Reset_pressed() -> void:
	if XRToolsUserSettings:
		XRToolsUserSettings.reset_to_defaults()
		_update()
		player_height_changed.emit(XRToolsUserSettings.player_height)


func _on_Save_pressed() -> void:
	if XRToolsUserSettings:
		# Save
		XRToolsUserSettings.save()


func _on_SnapTurningCB_pressed() -> void:
	XRToolsUserSettings.snap_turning = snap_turning_button.button_pressed


func _on_web_xr_primary_item_selected(index: int) -> void:
	XRToolsUserSettings.webxr_primary = index


func _on_x_axis_dead_zone_slider_value_changed(value: float) -> void:
	XRToolsUserSettings.x_axis_dead_zone = x_deadzone_slider.value


func _on_y_axis_dead_zone_slider_value_changed(value: float) -> void:
	XRToolsUserSettings.y_axis_dead_zone = y_deadzone_slider.value


func _update() -> void:
	# Input
	snap_turning_button.button_pressed = XRToolsUserSettings.snap_turning
	y_deadzone_slider.value = XRToolsUserSettings.y_axis_dead_zone
	x_deadzone_slider.value = XRToolsUserSettings.x_axis_dead_zone
	haptics_scale_slider.value = XRToolsUserSettings.haptics_scale

	# Player
	player_height_slider.value = XRToolsUserSettings.player_height

	# WebXR
	webxr_primary_button.selected = XRToolsUserSettings.webxr_primary
