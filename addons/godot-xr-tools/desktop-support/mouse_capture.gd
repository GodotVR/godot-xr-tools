@tool
class_name XRToolsDesktopMouseCapture
extends XRToolsMovementProvider

## XR Tools Mouse Capture
##
## This script provides support for desktop mouse capture. This script works
## with the PlayerBody attached to the players XROrigin3D.


## Movement provider order
@export var order : int = 1

## Our directional input
@export var escape_action : String = "ui_cancel"

#Last mouse capture status and should it be auto captured
@export var capture : bool = true


# XRStart node
@onready var xr_start_node = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,
	"*Staging",
	"XRToolsStaging"),"StartXR","Node")


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsDesktopMouseCapture" or super(name)


# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the player body isn't active
	var check1 :bool= (xr_start_node.is_xr_active() and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
	if !player_body.enabled or check1:
		return


	if Input.is_action_just_pressed("ui_cancel"):
		capture=!capture

	#print(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)

	if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and (xr_start_node.is_xr_active() or !capture):
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	elif (!xr_start_node.is_xr_active() and capture):
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	return

