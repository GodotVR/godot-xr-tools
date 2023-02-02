tool
class_name XRToolsSurfaceAudio, "res://addons/godot-xr-tools/editor/icons/foot.svg"
extends Node

## Surface STATES
enum STATE {
	DEFAULT = 0,
	FABRIC = 1,
	GLASS = 2,
	GRASS = 3,
	LEAFES = 4,
	METAL = 5,
	MUD = 6,
	PLASTIC = 7,
	PUDDLE = 8,
	RUBBER = 9,
	SAND = 10,
	SILK = 11,
	SNOW = 12,
	STONE = 13,
	TILE = 14,
	WATER = 15,
	WOOD = 16
}
## current_surface is the current surface the player is standing on
export (STATE) var current_surface = STATE.DEFAULT

# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsSurfaceAudio" or .is_class(name)
