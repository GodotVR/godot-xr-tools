tool
class_name Teleport
extends Spatial


## Scene base for the current scene
export var scene_base: NodePath

## Main scene file
export (String, FILE, '*.tscn') var scene : String

## Title texture
export var title: Texture setget _set_title

## Can Teleporter be used
export var active : bool = true setget _set_active

## Is teleport beam visible if inactive
export var inactive_beam_visible: bool = false setget _set_inactive_beam_visible

## The beam color in active state
export var active_beam_color: Color = Color("#2b40f8") setget _set_active_beam_color

## The beam color in inactive state
export var inactive_beam_color: Color = Color("#ad0400") setget _set_inactive_beam_color


# Scene base to trigger loading
onready var _scene_base: XRToolsSceneBase = get_node(scene_base)


func _ready():
	_update_title()
	_update_teleport()


# Called when the player enters the teleport area
func _on_TeleportArea_body_entered(body: Spatial):
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
	if scene != "":
		_scene_base.load_scene(scene)
	else:
		_scene_base.exit_to_main_menu()

func set_collision_disabled(value):
	if !Engine.is_editor_hint():
		for child in get_node("TeleportBody").get_children():
			if child is CollisionShape:
				child.disabled = value

func _set_title(value):
	title = value
	if is_inside_tree():
		_update_title()

func _update_title():
	if title:
		var material: ShaderMaterial = $TeleportBody/Top.get_active_material(1)
		material.set_shader_param("Title", title)

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
		$TeleportArea/Cylinder.get_surface_material(0).set_shader_param("beam_color", active_beam_color)
		$TeleportArea/Cylinder.visible = true
	else:
		$TeleportArea/Cylinder.get_surface_material(0).set_shader_param("beam_color", inactive_beam_color)
		$TeleportArea/Cylinder.visible = inactive_beam_visible
