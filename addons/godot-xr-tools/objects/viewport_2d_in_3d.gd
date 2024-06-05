@tool
extends Node3D


## XR ToolsViewport 2D in 3D
##
## This script manages a 2D scene rendered as a texture on a 3D quad.
##
## Pointer and keyboard input are mapped into the 2D scene.


## Signal for pointer events
signal pointer_event(event)


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


# The following dirty flags are private (leading _) to suppress them in the
# generated documentation. Unfortunately gdlint complaints on private constants
# (see https://github.com/Scony/godot-gdscript-toolkit/issues/223). Until this
# is fixed we suppress the rule.
# gdlint: disable=constant-name

# State dirty flags
const _DIRTY_NONE			:= 0x0000	# Everything up to date
const _DIRTY_MATERIAL		:= 0x0001	# Material needs update
const _DIRTY_SCENE			:= 0x0002	# Scene needs update
const _DIRTY_SIZE			:= 0x0004	# Viewport size needs update
const _DIRTY_ALBEDO			:= 0x0008	# Albedo texture needs update
const _DIRTY_UPDATE			:= 0x0010	# Update mode needs update
const _DIRTY_TRANSPARENCY	:= 0x0020	# Transparency needs update
const _DIRTY_ALPHA_SCISSOR	:= 0x0040	# Alpha scissor needs update
const _DIRTY_UNSHADED		:= 0x0080	# Shade mode needs update
const _DIRTY_FILTERED		:= 0x0100	# Filter mode needs update
const _DIRTY_SURFACE		:= 0x0200	# Surface material needs update
const _DIRTY_REDRAW			:= 0x0400	# Redraw required
const _DIRTY_ALL			:= 0x07FF	# All dirty

# Default layer of 1:static-world, 21:pointable, 23:ui-objects
const DEFAULT_LAYER := 0b0000_0000_0101_0000_0000_0000_0000_0001


# Physics property group
@export_group("Physics")

## Physical screen size property
@export var screen_size : Vector2 = Vector2(3.0, 2.0): set = set_screen_size

## Viewport collision enabled property
@export var enabled : bool = true: set = set_enabled

## Collision layer
@export_flags_3d_physics var collision_layer : int = DEFAULT_LAYER: set = set_collision_layer

# Content property group
@export_group("Content")

## Scene property
@export var scene : PackedScene: set = set_scene

## Viewport size property
@export var viewport_size : Vector2 = Vector2(300.0, 200.0): set = set_viewport_size

## Update Mode property
@export var update_mode : UpdateMode = UpdateMode.UPDATE_ALWAYS: set = set_update_mode

## Update throttle property
@export var throttle_fps : float = 30.0

# Input property group
@export_group("Input")

## Allow physical keyboard input to viewport
@export var input_keyboard : bool = true

## Allow gamepad input to viewport
@export var input_gamepad : bool = false

# Rendering property group
@export_group("Rendering")

## Custom material template
@export var material : StandardMaterial3D = null: set = set_material

## Transparent property
@export var transparent : TransparancyMode = TransparancyMode.TRANSPARENT: set = set_transparent

## Alpha Scissor Threshold property (ignored when custom material provided)
var alpha_scissor_threshold : float = 0.25: set = set_alpha_scissor_threshold

## Unshaded flag (ignored when custom material provided)
var unshaded : bool = false: set = set_unshaded

## Filtering flag (ignored when custom material provided)
var filter : bool = true: set = set_filter


var is_ready : bool = false
var scene_node : Node
var viewport_texture : ViewportTexture
var time_since_last_update : float = 0.0
var _screen_material : StandardMaterial3D
var _dirty := _DIRTY_ALL


# Called when the node enters the scene tree for the first time.
func _ready():
	is_ready = true

	# Listen for pointer events on the screen body
	$StaticBody3D.connect("pointer_event", _on_pointer_event)

	# Apply physics properties
	_update_screen_size()
	_update_enabled()
	_update_collision_layer()

	# Update the render objects
	_update_render()


# Provide custom property information
func _get_property_list() -> Array[Dictionary]:
	# Select visibility of properties
	var show_alpha_scissor := not material and transparent == TransparancyMode.SCISSOR
	var show_unshaded := not material
	var show_filter := not material

	# Return extra properties
	return [
		{
			name = "Rendering",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = "alpha_scissor_threshold",
			type = TYPE_FLOAT,
			usage = PROPERTY_USAGE_DEFAULT if show_alpha_scissor else PROPERTY_USAGE_NO_EDITOR,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0,1.0"
		},
		{
			name = "unshaded",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT if show_unshaded else PROPERTY_USAGE_NO_EDITOR
		},
		{
			name = "filter",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT if show_filter else PROPERTY_USAGE_NO_EDITOR
		}
	]


# Allow revert of custom properties
func _property_can_revert(property : StringName) -> bool:
	match property:
		"alpha_scissor_threshold":
			return true
		"unshaded":
			return true
		"filter":
			return true
		_:
			return false


# Provide revert values for custom properties
func _property_get_revert(property : StringName): # Variant
	match property:
		"alpha_scissor_threshold":
			return 0.25
		"unshaded":
			return false
		"filter":
			return true


## Get the 2D scene instance
func get_scene_instance() -> Node:
	return scene_node


## Connect a 2D scene signal
func connect_scene_signal(which : String, callback : Callable, flags : int = 0):
	if scene_node:
		scene_node.connect(which, callback, flags)


# Handle pointer event from screen-body
func _on_pointer_event(event : XRToolsPointerEvent) -> void:
	pointer_event.emit(event)


# Handler for input events
func _input(event):
	# Map keyboard events to the viewport if enabled
	if input_keyboard and (event is InputEventKey or event is InputEventShortcut):
		$Viewport.push_input(event)
		return

	# Map gamepad events to the viewport if enable
	if input_gamepad and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		$Viewport.push_input(event)
		return


# Process event
func _process(delta):
	# Process screen refreshing
	if Engine.is_editor_hint():
		# Perform periodic material refreshes to handle the user modifying the
		# material properties in the editor
		time_since_last_update += delta
		if time_since_last_update > 1.0:
			time_since_last_update = 0.0
			# Trigger material refresh
			_dirty = _DIRTY_MATERIAL
			_update_render()
	elif update_mode == UpdateMode.UPDATE_THROTTLED:
		# Perform throttled updates of the viewport
		var frame_time = 1.0 / throttle_fps
		time_since_last_update += delta
		if time_since_last_update > frame_time:
			time_since_last_update = 0.0
			# Trigger update
			$Viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		# This is no longer needed
		set_process(false)


## Set screen size property
func set_screen_size(new_size: Vector2) -> void:
	screen_size = new_size
	if is_ready:
		_update_screen_size()


## Set enabled property
func set_enabled(is_enabled: bool) -> void:
	enabled = is_enabled
	if is_ready:
		_update_enabled()


## Set collision layer property
func set_collision_layer(new_layer: int) -> void:
	collision_layer = new_layer
	if is_ready:
		_update_collision_layer()


## Set scene property
func set_scene(new_scene: PackedScene) -> void:
	scene = new_scene
	_dirty |= _DIRTY_SCENE
	if is_ready:
		_update_render()


## Set viewport size property
func set_viewport_size(new_size: Vector2) -> void:
	viewport_size = new_size
	_dirty |= _DIRTY_SIZE
	if is_ready:
		_update_render()


## Set update mode property
func set_update_mode(new_update_mode: UpdateMode) -> void:
	update_mode = new_update_mode
	_dirty |= _DIRTY_UPDATE
	if is_ready:
		_update_render()


## Set material property
func set_material(new_material: StandardMaterial3D) -> void:
	material = new_material
	notify_property_list_changed()
	_dirty |= _DIRTY_MATERIAL
	if is_ready:
		_update_render()


## Set transparent property
func set_transparent(new_transparent: TransparancyMode) -> void:
	transparent = new_transparent
	notify_property_list_changed()
	_dirty |= _DIRTY_TRANSPARENCY
	if is_ready:
		_update_render()


## Set the alpha scisser threshold
func set_alpha_scissor_threshold(new_threshold: float) -> void:
	alpha_scissor_threshold = new_threshold
	_dirty |= _DIRTY_ALPHA_SCISSOR
	if is_ready:
		_update_render()


## Set the unshaded property
func set_unshaded(new_unshaded : bool) -> void:
	unshaded = new_unshaded
	_dirty |= _DIRTY_UNSHADED
	if is_ready:
		_update_render()


## Set filter property
func set_filter(new_filter: bool) -> void:
	filter = new_filter
	_dirty |= _DIRTY_FILTERED
	if is_ready:
		_update_render()


# Screen size update handler
func _update_screen_size() -> void:
	$Screen.mesh.size = screen_size
	$StaticBody3D.screen_size = screen_size
	$StaticBody3D/CollisionShape3D.shape.size = Vector3(
			screen_size.x,
			screen_size.y,
			0.02)


# Enabled update handler
func _update_enabled() -> void:
	if Engine.is_editor_hint():
		return

	$StaticBody3D/CollisionShape3D.disabled = !enabled


# Collision layer update handler
func _update_collision_layer() -> void:
	$StaticBody3D.collision_layer = collision_layer


# This complex function processes the render dirty flags and performs the
# minimal number of updates to get the render objects into the correct state.
func _update_render() -> void:
	# Handle material change
	if _dirty & _DIRTY_MATERIAL:
		_dirty &= ~_DIRTY_MATERIAL

		# Construct the new screen material
		if material:
			# Copy custom material
			_screen_material = material.duplicate()
		else:
			# Create new local material
			_screen_material = StandardMaterial3D.new()

			# Disable culling
			_screen_material.params_cull_mode = StandardMaterial3D.CULL_DISABLED

			# Ensure local material is configured
			_dirty |= _DIRTY_TRANSPARENCY |	\
					_DIRTY_ALPHA_SCISSOR |	\
					_DIRTY_UNSHADED |		\
					_DIRTY_FILTERED

		# Ensure new material renders viewport onto surface
		_dirty |= _DIRTY_ALBEDO | _DIRTY_SURFACE

	# If we have no screen material then skip everything else
	if not _screen_material:
		return

	# Handle scene change
	if _dirty & _DIRTY_SCENE:
		_dirty &= ~_DIRTY_SCENE

		# Out with the old
		if is_instance_valid(scene_node):
			$Viewport.remove_child(scene_node)
			scene_node.queue_free()

		# In with the new
		if scene:
			# Instantiate provided scene
			scene_node = scene.instantiate()
			$Viewport.add_child(scene_node)
		elif $Viewport.get_child_count() == 1:
			# Use already-provided scene
			scene_node = $Viewport.get_child(0)

		# Ensure the new scene is rendered at least once
		_dirty |= _DIRTY_REDRAW

	# Handle viewport size change
	if _dirty & _DIRTY_SIZE:
		_dirty &= ~_DIRTY_SIZE

		# Set the viewport size
		$Viewport.size = viewport_size
		$StaticBody3D.viewport_size = viewport_size

		# Update our viewport texture, it will have changed
		_dirty |= _DIRTY_ALBEDO

	# Handle albedo change:
	if _dirty & _DIRTY_ALBEDO:
		_dirty &= ~_DIRTY_ALBEDO

		# Set the screen material to use the viewport for the albedo channel
		viewport_texture = $Viewport.get_texture()
		_screen_material.albedo_texture = viewport_texture

	# Handle update mode change
	if _dirty & _DIRTY_UPDATE:
		_dirty &= ~_DIRTY_UPDATE

		# Apply update rules
		if Engine.is_editor_hint():
			# Update once. Process function used for editor refreshes
			$Viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			set_process(true)
		elif update_mode == UpdateMode.UPDATE_ONCE:
			# Update once. Process function not used
			$Viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			set_process(false)
		elif update_mode == UpdateMode.UPDATE_ALWAYS:
			# Update always. Process function not used
			$Viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			set_process(false)
		elif update_mode == UpdateMode.UPDATE_THROTTLED:
			# Update once. Process function triggers periodic refresh
			$Viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			set_process(true)

	# Handle transparency update
	if _dirty & _DIRTY_TRANSPARENCY:
		_dirty &= ~_DIRTY_TRANSPARENCY

		# If using a temporary material then update transparency
		if _screen_material and not material:
			# Set the transparancy mode
			match transparent:
				TransparancyMode.OPAQUE:
					_screen_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				TransparancyMode.TRANSPARENT:
					_screen_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				TransparancyMode.SCISSOR:
					_screen_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR

		# Set the viewport background transparency mode and force a redraw
		$Viewport.transparent_bg = transparent != TransparancyMode.OPAQUE
		_dirty |= _DIRTY_REDRAW

	# Handle alpha scissor update
	if _dirty & _DIRTY_ALPHA_SCISSOR:
		_dirty &= ~_DIRTY_ALPHA_SCISSOR

		# If using a temporary material with alpha-scissor then update
		if _screen_material and not material and transparent == TransparancyMode.SCISSOR:
			_screen_material.params_alpha_scissor_threshold = alpha_scissor_threshold

	# Handle unshaded update
	if _dirty & _DIRTY_UNSHADED:
		_dirty &= ~_DIRTY_UNSHADED

		# If using a temporary material then update the shading mode and force a redraw
		if _screen_material and not material:
			_screen_material.shading_mode = (
				BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else
				BaseMaterial3D.SHADING_MODE_PER_PIXEL)
			#_dirty |= _DIRTY_REDRAW

	# Handle filter update
	if _dirty & _DIRTY_FILTERED:
		_dirty &= ~_DIRTY_FILTERED

		# If using a temporary material then update the filter mode and force a redraw
		if _screen_material and not material:
			_screen_material.texture_filter = (
				BaseMaterial3D.TEXTURE_FILTER_LINEAR if filter else
				BaseMaterial3D.TEXTURE_FILTER_NEAREST)
			#_dirty |= _DIRTY_REDRAW

	# Handle surface material update
	if _dirty & _DIRTY_SURFACE:
		_dirty &= ~_DIRTY_SURFACE

		# Set the screen to render using the new screen material
		$Screen.set_surface_override_material(0, _screen_material)

	# Handle forced redraw of the viewport
	if _dirty & _DIRTY_REDRAW:
		_dirty &= ~_DIRTY_REDRAW

		# Force a redraw of the viewport
		if Engine.is_editor_hint() or update_mode == UpdateMode.UPDATE_ONCE:
			$Viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
