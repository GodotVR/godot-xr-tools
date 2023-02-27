tool
class_name XRToolsInventoryBackpack, "res://addons/godot-xr-tools/editor/icons/backpack.svg"
extends Node


export (PackedScene) var backpack_scene
export var backpack_path := @""
onready var backpack := get_node(backpack_path) as XRToolsPickable
var left_pickup = null
var right_pickup = null


func _ready():
	left_pickup = get_parent().get_node("LeftHand/FunctionPickup")
	right_pickup = get_parent().get_node("RightHand/FunctionPickup")
	left_pickup.connect("has_picked_up", self, "_on_left_pickup")
	right_pickup.connect("has_picked_up", self, "_on_right_pickup")

	# if scene has a backpack, set the weapon snap zones to require
	# a group that does not exist so player can just pick up
	# a backpack without triggering snap zones
	if backpack != null:
		var inner_pack = backpack.get_node("In")
		var outer_pack = backpack.get_node("Out")
		var inner_snaps = inner_pack.get_children()
		var outer_snaps = outer_pack.get_children()
		for snap in inner_snaps:
			snap.grab_require = "disabled"
			#snap.connect("has_picked_up", self, "_on_snap_zone_picked_up_object")
		for snap in outer_snaps:
			snap.grab_require = "disabled"
			#snap.connect("has_picked_up", self, "_on_snap_zone_picked_up_object")


func _on_left_pickup(object):	
	var inventory = check_inventory_scene(object)

	if inventory == null:
		return

	if inventory == backpack_scene:
		var inner_pack = object.get_node("In")
		var outer_pack = object.get_node("Out")
		var inner_snaps = inner_pack.get_children()
		var outer_snaps = outer_pack.get_children()
		for snap in inner_snaps:
			snap.grab_require = ""
		for snap in outer_snaps:
			snap.grab_require = ""
		return


func _on_right_pickup(object):
	var inventory = check_inventory_scene(object)
	
	if inventory == null:
		return
	
	if inventory == backpack_scene:
		var inner_pack = object.get_node("In")
		var outer_pack = object.get_node("Out")
		var inner_snaps = inner_pack.get_children()
		var outer_snaps = outer_pack.get_children()
		for snap in inner_snaps:
			snap.grab_require = ""
		for snap in outer_snaps:
			snap.grab_require = ""
		return


# compare object to weapon .tscns used in game to determine which it is
func check_inventory_scene(object):
	if object.name.begins_with("SnapBackpack"):
		return backpack_scene
	return null


# If backpack dropped, freeze slots so player
# cannot accidentally grab weapons from slots while picking up backpack
func _on_SnapBackpack_dropped(pickable):
	var inner_pack = pickable.get_node("In")
	var outer_pack = pickable.get_node("Out")
	var inner_snaps = inner_pack.get_children()
	var outer_snaps = outer_pack.get_children()
	for snap in inner_snaps:
		snap.grab_require = "none"

	for snap in outer_snaps:
		snap.grab_require = "none"

	# example code to automatically return backpack
	# to player holster when dropped
	if pickable.picked_up_by == null and pickable.is_picked_up() == false:
		var shoulder_holster = get_tree().get_nodes_in_group("ShoulderHolster")

		if shoulder_holster == null:
			return

		for holster in shoulder_holster:
		#put on empty shoulder slot if one is available
			if holster.picked_up_object == null:
				holster._pick_up_object(backpack)
