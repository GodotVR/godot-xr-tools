@tool
class_name XRToolsDesktopMouseCapture
extends XRToolsMovementProvider

## XR Tools Mouse Capture
##
## This script provides support for desktop mouse capture. This script works
## with the PlayerBody attached to the player's [XROrigin3D].

## Movement provider order
@export var order: int = 1

## Our directional input
@export var escape_action: String = "ui_cancel"

## Last mouse capture status and should it be auto captured
@export var capture: bool = true


## XRStart node
@onready var xr_start_node: XRToolsStartXR = XRTools.find_xr_child(
		XRTools.find_xr_ancestor(
				self,
				"*Staging",
				"XRToolsStaging",
		),
		"StartXR",
		"Node",
)


## Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsDesktopMouseCapture" or super(xr_name)


## Perform jump movement
func physics_movement(
		_delta: float,
		player_body: XRToolsPlayerBody,
		_disabled: bool,
) -> void:
	# Skip if the player body isn't active
	var xr_active: bool = (
			xr_start_node.is_xr_active()
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	)

	if not player_body.enabled or xr_active:
		return

	if Input.is_action_just_pressed("ui_cancel"):
		capture = not capture

	if not xr_start_node.is_xr_active() and capture:
		# If XR is not active and the mouse should be captured
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# If XR is active and the mouse should not be captured
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	return
