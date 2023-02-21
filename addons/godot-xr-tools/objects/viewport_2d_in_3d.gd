tool
extends Spatial


## XR ToolsViewport 2D in 3D
##
## This script manages a 2D scene rendered as a texture on a 3D quad.
##
## Pointer and keyboard input are mapped into the 2D scene.


signal pointer_entered
signal pointer_exited


## Transparent property
enum TransparancyMode {
	OPAQUE,				## Render opaque
	TRANSPARENT,		## Render transparent
	SCISSOR,			## Render using alpha-scissor
}

## Viewport Update Mode
enum UpdateMode {
	UPDATE_ONCE, 		## Update once (redraw triggered if set again to UPDATE_ONCE)
	UPDATE_ALWAYS,		## Update on every frame
	UPDATE_THROTTLED,	## Update at throttled rate
}


# Default layer of 1:static-world and 21:pointable
const DEFAULT_LAYER := 0b0000_0000_0001_0000_0000_0000_0000_0001


## Viewport enabled property
export var enabled : bool = true setget set_enabled

## Screen size property
export var screen_size : Vector2 = Vector2(3.0, 2.0) setget set_screen_size

## Viewport size property
export var viewport_size : Vector2 = Vector2(300.0, 200.0) setget set_viewport_size

## Transparent property
export (TransparancyMode) \
		var transparent : int = TransparancyMode.TRANSPARENT setget set_transparent

## Alpha Scissor Threshold property
export var alpha_scissor_threshold : float = 0.25 setget set_alpha_scissor_threshold

## Unshaded
export var unshaded : bool = false setget set_unshaded

## Scene property
export var scene : PackedScene setget set_scene

## Display properties
export var filter : bool = true setget set_filter

## Update Mode property
export (UpdateMode) var update_mode = UpdateMode.UPDATE_ALWAYS setget set_update_mode

## Update throttle property
export var throttle_fps : float = 30.0

## Collision layer
export (int, LAYERS_3D_PHYSICS) \
		var collision_layer : int = DEFAULT_LAYER setget set_collision_layer


var is_ready : bool = false
var scene_node : Node
var viewport_texture : ViewportTexture
var material : SpatialMaterial
var time_since_last_update : float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	is_ready = true

	# Setup our viewport texture and material
	material = SpatialMaterial.new()
	material.flags_unshaded = true
	material.params_cull_mode = SpatialMaterial.CULL_DISABLED
	$Screen.set_surface_material(0, material)

	# apply properties
	_update_enabled()
	_update_screen_size()
	_update_viewport_size()
	_update_collision_layer()
	_update_scene()
	# _update_filter() ## already called from _update_viewport_size
	_update_update_mode()
	_update_collision_layer()
	_update_transparent()
	_update_unshaded()


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

# Process event
func _process(delta):
	if Engine.editor_hint:
		# Don't run in editor (will auto run on load)
		set_process(false)
		return

	if update_mode == UpdateMode.UPDATE_THROTTLED:
		var frame_time = 1.0 / throttle_fps
		time_since_last_update += delta
		if time_since_last_update > frame_time:
			# Trigger update
			$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE
			time_since_last_update = 0.0
	else:
		# This is no longer needed
		set_process(false)

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
func set_transparent(new_transparent: int) -> void:
	transparent = new_transparent
	if is_ready:
		_update_transparent()


# Set the alpha scisser threshold
func set_alpha_scissor_threshold(new_threshold: float) -> void:
	alpha_scissor_threshold = new_threshold
	if is_ready:
		_update_transparent()


# Set the unshaded property
func set_unshaded(new_unshaded : bool) -> void:
	unshaded = new_unshaded
	if is_ready:
		_update_unshaded()


# Set scene property
func set_scene(new_scene: PackedScene) -> void:
	scene = new_scene
	if is_ready:
		_update_scene()


# Set filter property
func set_filter(new_filter: bool) -> void:
	filter = new_filter
	if is_ready:
		_update_filter()

# Set update mode property
func set_update_mode(new_update_mode: int) -> void:
	update_mode = new_update_mode
	if is_ready:
		_update_update_mode()


# Set collision layer property
func set_collision_layer(new_layer: int) -> void:
	collision_layer = new_layer
	if is_ready:
		_update_collision_layer()


# Enabled update handler
func _update_enabled() -> void:
	if Engine.editor_hint:
		return

	$StaticBody/CollisionShape.disabled = !enabled


# Screen size update handler
func _update_screen_size() -> void:
	$Screen.mesh.size = screen_size
	$StaticBody.screen_size = screen_size
	$StaticBody/CollisionShape.shape.extents = Vector3(
			screen_size.x * 0.5,
			screen_size.y * 0.5,
			0.01)


# Viewport size update handler
func _update_viewport_size() -> void:
	$Viewport.size = viewport_size
	$StaticBody.viewport_size = viewport_size

	# Update our viewport texture, it will have changed
	viewport_texture = $Viewport.get_texture()
	if material:
		material.albedo_texture = viewport_texture
	_update_filter()


# Transparent update handler
func _update_transparent() -> void:
	if material:
		material.flags_transparent = transparent != TransparancyMode.OPAQUE
		material.params_use_alpha_scissor = transparent == TransparancyMode.SCISSOR
		if transparent == TransparancyMode.SCISSOR:
			material.params_alpha_scissor_threshold = alpha_scissor_threshold
	$Viewport.transparent_bg = transparent != TransparancyMode.OPAQUE

	# make sure we redraw the screen atleast once
	if Engine.editor_hint or update_mode == UpdateMode.UPDATE_ONCE:
		# this will trigger redrawing our screen
		$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE


# Unshaded update handler
func _update_unshaded() -> void:
	if material:
		material.flags_unshaded = unshaded

	# make sure we redraw the screen atleast once
	if Engine.editor_hint or update_mode == UpdateMode.UPDATE_ONCE:
		# this will trigger redrawing our screen
		$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE


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

	# (or use the scene if there is one already under the Viewport)
	elif $Viewport.get_child_count() == 1:
		scene_node = $Viewport.get_child(0)

	# make sure we update atleast once
	$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE


# Filter update handler
func _update_filter() -> void:
	if viewport_texture:
		viewport_texture.flags = Texture.FLAG_FILTER if filter else 0

	# make sure we redraw the screen atleast once
	if Engine.editor_hint or update_mode == UpdateMode.UPDATE_ONCE:
		# this will trigger redrawing our screen
		$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE


# Update mode handler
func _update_update_mode() -> void:
	if Engine.editor_hint:
		$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		return

	if update_mode == UpdateMode.UPDATE_ONCE:
		# this will trigger redrawing our screen
		$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		set_process(false)
	elif update_mode == UpdateMode.UPDATE_ALWAYS:
		# redraw screen every frame
		$Viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		set_process(false)
	elif update_mode == UpdateMode.UPDATE_THROTTLED:
		# we will attempt to update the screen at the given framerate
		$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		set_process(true)


# Collision layer update handler
func _update_collision_layer() -> void:
	$StaticBody.collision_layer = collision_layer
