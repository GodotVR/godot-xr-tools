tool
class_name XRToolsSurfaceAudio, "res://addons/godot-xr-tools/editor/icons/foot.svg"
extends Node

enum STATE {
	DEFAULT = 0,
	FABRIC = 1,
	GRASS = 2,
	METAL = 3,
	MUD = 4,
	PUDDLE = 5,
	SAND = 6,
	SNOW = 7,
	STONE = 8,
	TILE = 9,
	WATER = 10,
	WOOD = 11
}
export (STATE) var current_surface = STATE.DEFAULT

# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsSurfaceAudio" or .is_class(name)
