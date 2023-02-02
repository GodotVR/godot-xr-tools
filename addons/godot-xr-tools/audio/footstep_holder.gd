tool
class_name XRToolsFootstepHolder, "res://addons/godot-xr-tools/editor/icons/foot.svg"
extends Spatial

onready var default = $default
onready var fabric = $fabric
onready var grass = $grass
onready var metal = $metal
onready var mud = $mud
onready var puddle = $puddle
onready var sand = $sand
onready var snow = $snow
onready var stone = $stone
onready var tile = $tile
onready var water = $water
onready var wood = $wood

# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsFootstepHolder" or .is_class(name)

## Find an [XRToolsFootstepHolder] node.
##
## This function searches from the specified node for an [XRToolsFootstepHolder]
## assuming the node is a sibling of the body under an [ARVROrigin].
static func find_instance(node: Node) -> XRToolsFootstepHolder:
	return XRTools.find_child(
		ARVRHelpers.get_arvr_origin(node),
		"*",
		"XRToolsFootstepHolder") as XRToolsFootstepHolder
