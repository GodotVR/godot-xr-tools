@tool
extends XRToolsPickable

@onready var sniper_handle : XRToolsInteractableHandle = $sniper_rifle/FirearmSlide/HandleOrigin/InteractableHandle

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()

	# Disable by default
	sniper_handle.enabled = false


func _on_picked_up(pickable):
	# Enable on pickup
	sniper_handle.enabled = true


func _on_dropped(pickable):
	# Disable on drop
	sniper_handle.enabled = false
