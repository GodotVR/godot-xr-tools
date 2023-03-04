tool
class_name XRToolsInventoryBackpack, "res://scenes/pickable_demo/editor/icons/backpack.svg"
extends Node

# if set to true, backpack will return on drop after
# wait time passed
export var return_to_player : bool = false

# wait time for return to player bool
export var wait_time = 3

export var backpack_path: NodePath

# timer node to control the return to player time
var timer

# Array of all snap-zones in the backpack
var _backpack_snap_zones := []

onready var backpack: XRToolsPickable = get_node(backpack_path)


func _ready():
	timer = get_node("Timer")
	timer.connect("timeout", self, "_on_Timer_timeout")

	# Listen to when this backpack is picked up or dropped
	backpack.connect("picked_up", self, "_on_backpack_picked_up")
	backpack.connect("dropped", self, "_on_backpack_dropped")

	# Get all the snap-zones
	_backpack_snap_zones = XRTools.find_children(backpack, "*", "XRToolsSnapZone")

	# Disable all snap-zones in this backpack
	for snap in _backpack_snap_zones :
		snap.enabled = false


func _on_backpack_picked_up(_pickable):
	# Enable all snap-zones when picked up by a hand/controller
	if backpack.get_picked_up_by_controller():
		for snap in _backpack_snap_zones:
			snap.enabled = true

func _on_backpack_dropped(_pickable):
	# Disable all snap-zones when the backpack is dropped
	for snap in _backpack_snap_zones :
		snap.enabled = false

	if !return_to_player:
		# example code to automatically return backpack
		# to player holster when dropped
			if _pickable.picked_up_by == null and _pickable.is_picked_up() == false:
				var shoulder_holster = get_tree().get_nodes_in_group("ShoulderHolster")

				if shoulder_holster == null:
					return

				for holster in shoulder_holster:
				#put on empty shoulder slot if one is available
					if holster.picked_up_object == null:
						holster.pick_up_object(backpack)

	if return_to_player:
		# example code to automatically return backpack
		# to player holster when dropped after wait time passed
		if _pickable.picked_up_by == null and _pickable.is_picked_up() == false:
			timer.start(wait_time)


func _on_Timer_timeout():
	var shoulder_holster = get_tree().get_nodes_in_group("ShoulderHolster")

	if shoulder_holster == null:
		return

	for holster in shoulder_holster:
	#put on empty shoulder slot if one is available
		if holster.picked_up_object == null:
			holster.pick_up_object(backpack)
			break
