@tool
extends XRToolsPickable

@export var player_camera : Camera3D:
	set(value):
		player_camera = value
		if is_inside_tree():
			_update_player_camera()

func _update_player_camera():
	$sniper_rifle/ScopeDisplay.player_camera = player_camera

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	_update_player_camera()

