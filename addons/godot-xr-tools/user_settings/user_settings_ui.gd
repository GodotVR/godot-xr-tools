extends TabContainer

export (NodePath) var camera

export var player_head_height : float = 0.1

func _update():
	# Input
	$Input/SnapTurning/SnapTurningCB.pressed = XRToolsUserSettings.snap_turning

	# Player
	$Player/PlayerHeight/PlayerHeightSlider.value = XRToolsUserSettings.player_height_adjust

# Called when the node enters the scene tree for the first time.
func _ready():
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

# Input settings changed
func _on_SnapTurningCB_pressed():
	XRToolsUserSettings.snap_turning = $Input/SnapTurning/SnapTurningCB.pressed

# Player settings changed
func _on_PlayerHeightSlider_drag_ended(_value_changed):
	XRToolsUserSettings.player_height_adjust = $Player/PlayerHeight/PlayerHeightSlider.value


func _on_PlayerHeightStandard_pressed():
	if !camera:
		return

	var camera_node = get_node_or_null(camera)
	if !camera_node:
		return

	var base_height = camera_node.transform.origin.y + player_head_height
	var height_adjust = XRTools.get_player_standard_height() - base_height
	XRToolsUserSettings.player_height_adjust = height_adjust
	$Player/PlayerHeight/PlayerHeightSlider.value = XRToolsUserSettings.player_height_adjust
