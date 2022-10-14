tool
extends Spatial


##
## Viewport 2D in 3D
##
## @desc:
##     This script manages a 2D scene rendered as a texture on a 3D quad.
##
##     Pointer and keyboard input are mapped into the 2D scene.
##


signal pointer_entered
signal pointer_exited


## Viewport enabled property
export var enabled : bool = true setget set_enabled

## Screen size property
export var screen_size : Vector2 = Vector2(3.0, 2.0) setget set_screen_size

## Viewport size property
export var viewport_size : Vector2 = Vector2(300.0, 200.0) setget set_viewport_size

## Transparent property
export var transparent : bool = true setget set_transparent

## Scene property
export var scene : PackedScene setget set_scene

## Collision layer
export (int, LAYERS_3D_PHYSICS) var collision_layer : int = 15 setget set_collision_layer


var is_ready : bool = false
var scene_node : Node


# Called when the node enters the scene tree for the first time.
func _ready():
	# Do not initialize if in the editor
	if Engine.editor_hint:
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


# Get the 2D scene instance
func get_scene_instance():
	return scene_node


# Connect a 2D scene signal
func connect_scene_signal(which, on, callback):
	if scene_node:
		scene_node.connect(which, on, callback)


# Handler for pointer entered
func _on_pointer_entered():
	emit_signal("pointer_entered")


# Handler for pointer exited
func _on_pointer_exited():
	emit_signal("pointer_exited")


# Handler for input eventsd
func _input(event):
	$Viewport.input(event)


# Set enabled property
func set_enabled(is_enabled: bool) -> void:
	enabled = is_enabled
	if is_ready:
		_update_enabled()


# Set screen size property
func set_screen_size(new_size: Vector2) -> void:
	screen_size = new_size
	if is_ready:
		_update_screen_size()


# Set viewport size property
func set_viewport_size(new_size: Vector2) -> void:
	viewport_size = new_size
	if is_ready:
		_update_viewport_size()


# Set transparent property
func set_transparent(new_transparent: bool) -> void:
	transparent = new_transparent
	if is_ready:
		_update_transparent()


# Set scene property
func set_scene(new_scene: PackedScene) -> void:
	scene = new_scene
	if is_ready:
		_update_scene()


# Set collision layer property
func set_collision_layer(new_layer: int) -> void:
	collision_layer = new_layer
	if is_ready:
		_update_collision_layer()


# Enabled update handler
func _update_enabled() -> void:
	$StaticBody/CollisionShape.disabled = !enabled


# Screen size update handler
func _update_screen_size() -> void:
	$Screen.mesh.size = screen_size
	$StaticBody.screen_size = screen_size
	$StaticBody/CollisionShape.shape.extents = Vector3(screen_size.x * 0.5, screen_size.y * 0.5, 0.01)


# Viewport size update handler
func _update_viewport_size() -> void:
	$Viewport.size = viewport_size
	$StaticBody.viewport_size = viewport_size
	var material : SpatialMaterial = $Screen.get_surface_material(0)
	material.albedo_texture = $Viewport.get_texture()


# Transparent update handler
func _update_transparent() -> void:
	var material : SpatialMaterial = $Screen.get_surface_material(0)
	material.flags_transparent = transparent
	$Viewport.transparent_bg = transparent


# Scene update handler
func _update_scene() -> void:
	# out with the old
	if scene_node:
		$Viewport.remove_child(scene_node)
		scene_node.queue_free()

	# in with the new
	if scene:
		scene_node = scene.instance()
		$Viewport.add_child(scene_node)


# Collision layer update handler
func _update_collision_layer() -> void:
	$StaticBody.collision_layer = collision_layer
