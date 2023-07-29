extends TabContainer

signal player_height_changed(new_height)

@onready var snap_turning_button = $Input/InputVBox/SnapTurning/SnapTurningCB
@onready var y_deadzone_slider = $Input/InputVBox/yAxisDeadZone/yAxisDeadZoneSlider
@onready var x_deadzone_slider = $Input/InputVBox/xAxisDeadZone/xAxisDeadZoneSlider
@onready var player_height_slider = $Player/PlayerVBox/PlayerHeight/PlayerHeightSlider
@onready var webxr_primary_button = $WebXR/WebXRVBox/WebXR/WebXRPrimary

func _update():
	# Input
	snap_turning_button.button_pressed = XRToolsUserSettings.snap_turning
	y_deadzone_slider.value = XRToolsUserSettings.y_axis_dead_zone
	x_deadzone_slider.value = XRToolsUserSettings.x_axis_dead_zone

	# Player
	player_height_slider.value = XRToolsUserSettings.player_height

	# WebXR
	webxr_primary_button.selected = XRToolsUserSettings.webxr_primary


# Called when the node enters the scene tree for the first time.
func _ready():
	var webxr_interface = XRServer.find_interface("WebXR")
	set_tab_hidden(2, webxr_interface == null)

	if XRToolsUserSettings:
		_update()
	else:
		$Save/Button.disabled = true


func _on_Save_pressed():
	if XRToolsUserSettings:
		# Save
		XRToolsUserSettings.save()


func _on_Reset_pressed():
	if XRToolsUserSettings:
		XRToolsUserSettings.reset_to_defaults()
		_update()
		emit_signal("player_height_changed", XRToolsUserSettings.player_height)


# Input settings changed
func _on_SnapTurningCB_pressed():
	XRToolsUserSettings.snap_turning = snap_turning_button.button_pressed


# Player settings changed
func _on_PlayerHeightSlider_drag_ended(_value_changed):
	XRToolsUserSettings.player_height = player_height_slider.value
	emit_signal("player_height_changed", XRToolsUserSettings.player_height)


func _on_web_xr_primary_item_selected(index: int) -> void:
	XRToolsUserSettings.webxr_primary = index


func _on_y_axis_dead_zone_slider_value_changed(value):
	XRToolsUserSettings.y_axis_dead_zone = y_deadzone_slider.value

func _on_x_axis_dead_zone_slider_value_changed(value):
	XRToolsUserSettings.x_axis_dead_zone = x_deadzone_slider.value

