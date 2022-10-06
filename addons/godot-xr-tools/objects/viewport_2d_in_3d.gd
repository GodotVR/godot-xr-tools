@tool
extends Node3D

signal pointer_entered
signal pointer_exited

@export var enabled = true:
	set(new_value):
		enabled = new_value
		if is_ready:
			_update_enabled()

func _update_enabled():
	$StaticBody3D/CollisionShape3D.disabled = !enabled

@export var screen_size = Vector2(3.0, 2.0):
	set(new_value):
		screen_size = new_value
		if is_ready:
			_update_screen_size()

func _update_screen_size():
	$Screen.mesh.size = screen_size
	$StaticBody3D.screen_size = screen_size
	$StaticBody3D/CollisionShape3D.shape.extents = Vector3(screen_size.x * 0.5, screen_size.y * 0.5, 0.01)

@export var viewport_size = Vector2(300.0, 200.0):
	set(new_value):
		viewport_size = new_value
		if is_ready:
			_update_viewport_size()

func _update_viewport_size():
	$Viewport.size = viewport_size
	$StaticBody3D.viewport_size = viewport_size
	var material : StandardMaterial3D = $Screen.get_surface_override_material(0)
	material.albedo_texture = $Viewport.get_texture()

@export var transparent = true:
	set(new_value):
		transparent = new_value
		if is_ready:
			_update_transparent()

func _update_transparent():
	var material : StandardMaterial3D = $Screen.get_surface_override_material(0)
	material.flags_transparent = transparent
	$Viewport.transparent_bg = transparent

@export var scene : PackedScene:
	set(new_value):
		scene = new_value
		if is_ready:
			_update_scene()

func _update_scene():
	# out with the old
	if scene_node:
		$Viewport.remove_child(scene_node)
		scene_node.queue_free()

	# in with the new
	if scene:
		scene_node = scene.instantiate()
		$Viewport.add_child(scene_node)

@export_flags_3d_physics var collision_layer = 15:
	set(new_value):
		collision_layer = new_value
		if is_ready:
			_update_collision_layer()

func _update_collision_layer():
	$StaticBody3D.collision_layer = collision_layer

var is_ready = false
var scene_node = null

func get_scene_instance():
	return scene_node

func connect_scene_signal(which, on, callback):
	if scene_node:
		scene_node.connect(which, on, callback)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Do not run setup if in the editor
	if Engine.is_editor_hint():
		return

	# apply properties
	is_ready = true
	_update_enabled()
	_update_screen_size()
	_update_viewport_size()
	_update_collision_layer()
	_update_scene()
	_update_collision_layer()
	_update_transparent()

func _on_pointer_entered():
	emit_signal("pointer_entered")

func _on_pointer_exited():
	emit_signal("pointer_exited")
