@tool
class_name Teleport
extends Node3D


## Type of spawn-point data
enum SpawnDataType {
	## No data provided
	NONE,

	## Name of spawn-point node provided
	NODE_NAME,

	## Vector3 of spawn-point provided
	VECTOR3,

	## Transform3D of spawn-point provided
	TRANSFORM3D
}


@export_group("Teleport")

## Target scene file
@export_file('*.tscn') var scene : String

## Spawn point data
@export var spawn_data := SpawnDataType.NONE: set = _set_spawn_data

@export_group("Display")

## Title texture
@export var title: Texture2D: set = _set_title

## Can Teleporter be used
@export var active: bool = true: set = _set_active

## Is teleport beam visible if inactive
@export var inactive_beam_visible: bool = false: set = _set_inactive_beam_visible

## The beam color in active state
@export var active_beam_color: Color = Color("#2b40f8"): set = _set_active_beam_color

## The beam color in inactive state
@export var inactive_beam_color: Color = Color("#ad0400"): set = _set_inactive_beam_color


# Spawn point node-name
var spawn_point_name := ""

# Spawn point position
var spawn_point_position := Vector3.ZERO

# Spawn point transform
var spawn_point_transform := Transform3D.IDENTITY

# Scene base
var _scene_base : XRToolsSceneBase


func _ready():
	_scene_base = XRTools.find_xr_ancestor(self, "*", "XRToolsSceneBase")
	_update_title()
	_update_teleport()


# Called when the player enters the teleport area
func _on_TeleportArea_body_entered(body: Node3D):
	# Skip if scene base is not known
	if not _scene_base:
		return

	# Skip if not the player body
	if not body.is_in_group("player_body"):
		return

	# Skip if not active
	if not active:
		return

	# Teleport
	if scene == "":
		_scene_base.exit_to_main_menu()
	elif spawn_data == SpawnDataType.NODE_NAME:
		_scene_base.load_scene(scene, spawn_point_name)
	elif spawn_data == SpawnDataType.VECTOR3:
		_scene_base.load_scene(scene, spawn_point_position)
	elif spawn_data == SpawnDataType.TRANSFORM3D:
		_scene_base.load_scene(scene, spawn_point_transform)
	else:
		_scene_base.load_scene(scene)


# Provide custom property information
func _get_property_list() -> Array[Dictionary]:
	# Return extra properties
	return [
		{
			name = "Teleport",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = "spawn_point_name",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT \
					if spawn_data == SpawnDataType.NODE_NAME \
					else PROPERTY_USAGE_NO_EDITOR
		},
		{
			name = "spawn_point_position",
			type = TYPE_VECTOR3,
			usage = PROPERTY_USAGE_DEFAULT \
					if spawn_data == SpawnDataType.VECTOR3 \
					else PROPERTY_USAGE_NO_EDITOR
		},
		{
			name = "spawn_point_transform",
			type = TYPE_TRANSFORM3D,
			usage = PROPERTY_USAGE_DEFAULT \
					if spawn_data == SpawnDataType.TRANSFORM3D \
					else PROPERTY_USAGE_NO_EDITOR
		}
	]


# Allow revert of custom properties
func _property_can_revert(property : StringName) -> bool:
	match property:
		"spawn_point_name":
			return true
		"spawn_point_position":
			return true
		"spawn_point_transform":
			return true
		_:
			return false


# Provide revert values for custom properties
func _property_get_revert(property : StringName): # Variant
	match property:
		"spawn_point_name":
			return ""
		"spawn_point_position":
			return Vector3.ZERO
		"spawn_point_transform":
			return Transform3D.IDENTITY


func set_collision_disabled(value):
	if !Engine.is_editor_hint():
		for child in get_node("TeleportBody").get_children():
			if child is CollisionShape3D:
				child.disabled = value


func _set_spawn_data(p_spawn_data : SpawnDataType) -> void:
	spawn_data = p_spawn_data
	notify_property_list_changed()


func _set_title(value):
	title = value
	if is_inside_tree():
		_update_title()


func _update_title():
	if title:
		var material: ShaderMaterial = $TeleportBody/Top.get_active_material(1)
		material.set_shader_parameter("Title", title)


func _set_active(value):
	active = value
	if is_inside_tree():
		_update_teleport()


func _set_active_beam_color(value):
	active_beam_color = value
	if is_inside_tree():
		_update_teleport()


func _set_inactive_beam_color(value):
	inactive_beam_color = value
	if is_inside_tree():
		_update_teleport()


func _set_inactive_beam_visible(value):
	inactive_beam_visible = value
	if is_inside_tree():
		_update_teleport()


func _update_teleport():
	if active:
		$TeleportArea/Cylinder.get_surface_override_material(0).set_shader_parameter("beam_color", active_beam_color)
		$TeleportArea/Cylinder.visible = true
	else:
		$TeleportArea/Cylinder.get_surface_override_material(0).set_shader_parameter("beam_color", inactive_beam_color)
		$TeleportArea/Cylinder.visible = inactive_beam_visible
