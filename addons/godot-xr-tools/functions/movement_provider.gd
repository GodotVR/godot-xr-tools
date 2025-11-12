@tool
@icon("res://addons/godot-xr-tools/editor/icons/movement_provider.svg")
class_name XRToolsMovementProvider
extends Node3D


## XR Tools Movement Provider base class
##
## This movement provider class is the base class of all movement providers.
## Movement providers are invoked by the [XRToolsPlayerBody] object in order
## to apply motion to the player.
##
## Movement provider implementations should:
##  - Export an 'order' integer to control order of processing
##  - Override the physics_movement method to impelment motion


## Player body scene
const PLAYER_BODY := preload("res://addons/godot-xr-tools/player/player_body.tscn")


## Enable movement provider
@export var enabled : bool = true


## If true, the movement provider is actively performing a move
var is_active := false


# If missing we need to add our [XRToolsPlayerBody]
func _create_player_body_node():
	# get our origin node
	var xr_origin = XRHelpers.get_xr_origin(self)
	if !xr_origin:
		return

	# Double check if it hasn't already been created by another movement function
	var player_body := XRToolsPlayerBody.find_instance(self)
	if !player_body:
		# create our XRToolsPlayerBody node and add it into our tree
		player_body = PLAYER_BODY.instantiate()
		player_body.set_name("PlayerBody")
		xr_origin.add_child(player_body)
		player_body.set_owner(get_tree().get_edited_scene_root())


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsMovementProvider"


# Function run when node is added to scene
func _ready():
	# If we're in the editor, help the user out by creating our XRToolsPlayerBody node
	# automatically when needed.
	if Engine.is_editor_hint():
		var player_body = XRToolsPlayerBody.find_instance(self)
		if !player_body:
			# This call needs to be deferred, we can't add nodes during scene construction
			call_deferred("_create_player_body_node")


## Override this method to perform pre-movement updates to the PlayerBody
func physics_pre_movement(_delta: float, _player_body: XRToolsPlayerBody):
	pass


## Override this method to apply motion to the PlayerBody
func physics_movement(_delta: float, _player_body: XRToolsPlayerBody, _disabled: bool):
	pass


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify we're within the tree of an XROrigin3D node
	if !XRHelpers.get_xr_origin(self):
		warnings.append("This node must be within a branch on an XROrigin3D node")

	if !XRToolsPlayerBody.find_instance(self):
		warnings.append("Missing PlayerBody node on the XROrigin3D")

	# Verify movement provider is in the correct group
	if !is_in_group("movement_providers"):
		warnings.append("Movement provider not in 'movement_providers' group")

	# Verify order property exists
	if !"order" in self:
		warnings.append("Movement provider does not expose an order property")

	# Return warnings
	return warnings
