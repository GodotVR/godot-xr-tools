tool
class_name Teleport
extends Spatial


## Scene base for the current scene
export var scene_base: NodePath

## Scene to teleport to, or none for main menu
export var scene: PackedScene

## Title texture
export var title: Texture setget _set_title

## Can Teleporter be used
export var active := true


# Scene base to trigger loading
onready var _scene_base: XRToolsSceneBase = get_node(scene_base)


func _ready():
	_update_title()


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
	if scene:
		_scene_base.emit_signal("load_scene", scene.resource_path)
	else:
		_scene_base.emit_signal("exit_to_main_menu")

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
