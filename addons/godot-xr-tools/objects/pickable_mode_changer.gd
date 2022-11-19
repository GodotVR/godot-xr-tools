tool
extends Spatial
class_name XRToolsPickupModeChanger

##
## Pickable Util Node
##
## @desc:
##     This script RigidBody changes rigid body original_mode value after pickup.
##

export(int, "Rigid", "Static") var mode = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent() is XRToolsPickable:
# warning-ignore:return_value_discarded
		get_parent().connect("picked_up",self,"on_event")

func on_event(_a=null):
	if get_parent().original_mode!=mode:
		get_parent().original_mode=mode
	return

func _get_configuration_warning():
	# Check for error cases when not child of XRToolsPickable
	if not get_parent() is XRToolsPickable:
		return "Not child of 'XRToolsPickable'"
	# No issues found
	return ""
