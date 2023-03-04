@tool
class_name XRToolsStaging
extends Node3D


## XR Tools Staging
##
## When creating a game with multiple levels where you want to
## make use of background loading and have some nice structure
## in place, the Staging scene can be used as a base to handle
## all the startup and scene switching code.
## Just inherit this scene, set it up and make the resulting
## scene your startup scene.
##
## As different XR runtimes need slightly different setups you'll
## need to add the appropriate ARVROrigin setup to your scene.
## When using the OpenXR plugin this is as simple as adding the
## FPController script as a child node.
##
## Furthermore this scene has our loading screen and an anchor
## point into which we load the actual scene we wish the user
## to interact with. You can configure the first scene to load
## and kick off your game by setting the Main Scene property.
##
## If you are creating a game with a single level you may wish to
## simplify things. Check out the demo included in the source
## repository for the OpenXR plugin and then use the techniques
## explained in individual demos found here.


## Current scene is being unloaded
signal scene_exiting(scene)

## Switched to the loading scene
signal switching_to_loading_scene

## New scene has been loaded
signal scene_loaded(scene)

## New scene is now visible
signal scene_visible(scene)

## XR interaction started
signal xr_started

## XR interaction ended
signal xr_ended


## Main scene file
@export_file('*.tscn') var main_scene : String

## If true, the player is prompted to continue
@export var prompt_for_continue : bool = true


# Current scene
var current_scene : XRToolsSceneBase

# Current scene path
var current_scene_path : String

# Tween for fading
var _tween : Tween


## WorldEnvironment
##
## You will note that our staging scene has a world environment
## node included. Godot does not have a mechanism for having
## multiple world environments in our scene and marking one as
## active which makes it impractical to embed these in our demo
## scenes. Instead we will obtain the environment from our demo
## scene and manage it here. Our world environment at the start
## belongs to our loading screen and we need to keep a copy.
@onready var loading_screen_environment = $WorldEnvironment.environment

## XR Origin
@onready var xr_origin : XROrigin3D = XRHelpers.get_xr_origin(self)

## XR Camera
@onready var xr_camera : XRCamera3D = XRHelpers.get_xr_camera(self)


func _ready():
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Specify the camera to track
	if xr_camera:
		$LoadingScreen.set_camera(xr_camera)

	# We start by loading our main level scene
	load_scene(main_scene)


# Verifies our staging has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Report missing XR Origin
	var test_origin : XROrigin3D = XRHelpers.get_xr_origin(self)
	if !test_origin:
		warnings.append("No XROrigin3D node found, please add one")

	# Report missing XR Camera
	var test_camera : XRCamera3D = XRHelpers.get_xr_camera(self)
	if !test_camera:
		warnings.append("No XRCamera3D node found, please add one to your XROrigin3D node")

	# Report main scene not specified
	if main_scene == "":
		warnings.append("No main scene selected")

	# Report main scene invalid
	if !FileAccess.file_exists(main_scene):
		warnings.append("Main scene doesn't exist")

	# Return warnings
	return warnings


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsStaging"


## Load the specified scene
func load_scene(p_scene_path : String) -> void:
	# Do not load if in the editor
	if Engine.is_editor_hint():
		return

	if !xr_origin:
		return

	if !xr_camera:
		return

	if current_scene:
		# Start by unloading our scene

		# Let the scene know we're about to remove it
		current_scene.scene_pre_exiting()

		# Remove signals
		_remove_signals(current_scene)

		# Fade to black
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween()
		_tween.tween_method(set_fade, 0.0, 1.0, 1.0)
		await _tween.finished

		# Now we remove our scene
		emit_signal("scene_exiting", current_scene)
		current_scene.scene_exiting()
		$Scene.remove_child(current_scene)
		current_scene.queue_free()
		current_scene = null

		# Make our loading screen visible again and reset some stuff
		xr_origin.set_process_internal(true)
		xr_origin.current = true
		xr_camera.current = true
		$WorldEnvironment.environment = loading_screen_environment
		$LoadingScreen.progress = 0.0
		$LoadingScreen.enable_press_to_continue = false
		$LoadingScreen.follow_camera = true
		$LoadingScreen.visible = true
		emit_signal("switching_to_loading_scene")

		# Fade to visible
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween()
		_tween.tween_method(set_fade, 1.0, 0.0, 1.0)
		await _tween.finished

	# Load the new scene
	var new_scene : PackedScene
	if ResourceLoader.has_cached(p_scene_path):
		# Load cached scene
		new_scene = ResourceLoader.load(p_scene_path)
	else:
		# Start the loading in a thread
		ResourceLoader.load_threaded_request(p_scene_path)

		# Loop waiting for the scene to load
		while true:
			var progress := []
			var res := ResourceLoader.load_threaded_get_status(p_scene_path, progress)
			if res != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				break;

			$LoadingScreen.progress = progress[0]
			await get_tree().create_timer(0.1).timeout

		# Get the loaded scene
		new_scene = ResourceLoader.load_threaded_get(p_scene_path)

	# Wait for user to be ready
	if prompt_for_continue:
		$LoadingScreen.enable_press_to_continue = true
		await $LoadingScreen.continue_pressed

	# Fade to black
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.tween_method(set_fade, 0.0, 1.0, 1.0)
	await _tween.finished

	# Hide our loading screen
	$LoadingScreen.follow_camera = false
	$LoadingScreen.visible = false

	# Turn off internal process on our FPController, the internal process
	# of our XROrigin3D will submit its positioning data to the XRServer.
	# With two XROrigin3D nodes we'll get competing data.
	xr_origin.set_process_internal(false)

	# Setup our new scene
	current_scene = new_scene.instantiate()
	current_scene_path = p_scene_path
	$Scene.add_child(current_scene)
	$WorldEnvironment.environment = current_scene.environment
	_add_signals(current_scene)

	# We create a small delay here to give tracking some time to update our nodes...
	await get_tree().create_timer(0.1).timeout
	current_scene.scene_loaded()
	emit_signal("scene_loaded", current_scene)

	# Fade to visible
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.tween_method(set_fade, 1.0, 0.0, 1.0)
	await _tween.finished

	current_scene.scene_visible()
	emit_signal("scene_visible", current_scene)


## Fade
##
## Our fade object allows us to black out the screen for transitions.
## Note that our AABB is set to HUGE so it should always be rendered
## unless hidden.
func set_fade(p_value : float):
	if p_value == 0.0:
		$Fade.visible = false
	else:
		var material : ShaderMaterial = $Fade.get_surface_override_material(0)
		if material:
			material.set_shader_parameter("alpha", p_value)
		$Fade.visible = true


func _add_signals(p_scene : XRToolsSceneBase):
	p_scene.connect("request_exit_to_main_menu", _on_exit_to_main_menu)
	p_scene.connect("request_load_scene", _on_load_scene)
	p_scene.connect("request_reset_scene", _on_reset_scene)


func _remove_signals(p_scene : XRToolsSceneBase):
	p_scene.disconnect("request_exit_to_main_menu", _on_exit_to_main_menu)
	p_scene.disconnect("request_load_scene", _on_load_scene)
	p_scene.disconnect("request_reset_scene", _on_reset_scene)


func _on_exit_to_main_menu():
	load_scene(main_scene)


func _on_load_scene(p_scene_path : String):
	load_scene(p_scene_path)


func _on_reset_scene():
	load_scene(current_scene_path)


func _on_StartXR_xr_started():
	emit_signal("xr_started")


func _on_StartXR_xr_ended():
	emit_signal("xr_ended")
