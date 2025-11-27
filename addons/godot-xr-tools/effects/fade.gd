@tool
class_name XRToolsFade
extends Node3D


## XR Tools Fade Script
##
## This script manages fading the view.

@export_flags_3d_render var layers = 2:
	set(value):
		layers = value
		if _mesh:
			_mesh.layers = layers

# Dictionary of fade requests
var _faders : Dictionary = {}

# Fade update flag
var _update : bool = false

# Fade mesh
var _mesh : MeshInstance3D

# Fade shader material
var _material : ShaderMaterial


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsFade"


# Called when the fade node is ready
func _ready() -> void:
	# Add to the fade_mesh group - in the future this should be replaced with
	# static instances.
	add_to_group("fade_mesh")

	# Get the mesh and material
	_mesh = $FadeMesh
	if _mesh:
		_mesh.layers = layers
		_material = _mesh.get_surface_override_material(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float) -> void:
	# Skip if nothing to update
	if not _update:
		return

	# Calculate the cumulative shade color
	var fade := Color(1, 1, 1, 0)
	var show := false
	for whom in _faders:
		var color := _faders[whom] as Color
		fade = fade.blend(color)
		show = true

	# Set the shader and show if necessary
	_material.set_shader_parameter("albedo", fade)
	_mesh.visible = show
	_update = false


# Set the fade level
func set_fade_level(p_whom : Variant, p_color : Color) -> void:
	# Test if fading is needed
	if p_color.a > 0:
		# Set the fade level
		_faders[p_whom] = p_color
		_update = true
	elif _faders.erase(p_whom):
		# Fade erased
		_update = true


## Returns our first current fade node
static func get_fade_node() -> XRToolsFade:
	# In the future this use of groups should be replaced by static instances.
	var tree := Engine.get_main_loop() as SceneTree
	for node in tree.get_nodes_in_group("fade_mesh"):
		var fade := node as XRToolsFade
		if fade:
			return fade

	return null

## Set the fade level on the fade instance
static func set_fade(p_whom : Variant, p_color : Color) -> void:
	# In the future this use of groups should be replaced by static instances.
	var tree := Engine.get_main_loop() as SceneTree
	for node in tree.get_nodes_in_group("fade_mesh"):
		var fade := node as XRToolsFade
		if fade:
			fade.set_fade_level(p_whom, p_color)
