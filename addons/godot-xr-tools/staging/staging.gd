tool
class_name XRToolsStaging
extends Spatial


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
export (String, FILE, '*.tscn') var main_scene : String

## If true, the player is prompted to continue
export var prompt_for_continue : bool = true


# Current scene
var current_scene : XRToolsSceneBase

# Current scene path
var current_scene_path : String


## WorldEnvironment
##
## You will note that our staging scene has a world environment
## node included. Godot does not have a mechanism for having
## multiple world environments in our scene and marking one as
## active which makes it impractical to embed these in our demo
## scenes. Instead we will obtain the environment from our demo
## scene and manage it here. Our world environment at the start
## belongs to our loading screen and we need to keep a copy.
onready var loading_screen_environment = $WorldEnvironment.environment

## Resource queue for loading resources
onready var resource_queue = XRToolsResourceQueue.new()

## XR Origin
onready var arvr_origin : ARVROrigin = ARVRHelpers.get_arvr_origin(self)

## XR Camera
onready var arvr_camera : ARVRCamera = ARVRHelpers.get_arvr_camera(self)


func _ready():
	# Do not initialise if in the editor
	if Engine.editor_hint:
		return

	# Specify the camera to track
	if arvr_camera:
		$LoadingScreen.set_camera(arvr_camera)

	# Start our resource loader
	resource_queue.start()

	# We start by loading our main level scene
	load_scene(main_scene)


# Verifies our staging has a valid configuration.
func _get_configuration_warning():
	# Report missing XR Origin
	var test_origin : ARVROrigin = ARVRHelpers.get_arvr_origin(self)
	if !test_origin:
		return "No ARVROrigin node found, please add one"

	# Report missing XR Camera
	var test_camera : ARVRCamera = ARVRHelpers.get_arvr_camera(self)
	if !test_camera:
		return "No ARVRCamera node found, please add one to your ARVROrigin node"

	# Report main scene not specified
	if main_scene == "":
		return "No main scene selected"

	# Report main scene invalid
	var file = File.new()
	if !file.file_exists(main_scene):
		return "Main scene doesn't exist"

	# Passed validation
	return ""


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsStaging" or .is_class(name)


## Load the specified scene
func load_scene(p_scene_path : String) -> void:
	# Do not load if in the editor
	if Engine.editor_hint:
		return

	if !arvr_origin:
		return

	if !arvr_camera:
		return

	if current_scene:
		# Start by unloading our scene

		# Let the scene know we're about to remove it
		current_scene.scene_pre_exiting()

		# Remove signals
		_remove_signals(current_scene)

		# Fade to black
		$Tween.remove_all()
		$Tween.interpolate_method(self, "set_fade", 0.0, 1.0, 1.0)
		$Tween.start()
		yield($Tween, "tween_all_completed")

		# Now we remove our scene
		emit_signal("scene_exiting", current_scene)
		current_scene.scene_exiting()
		$Scene.remove_child(current_scene)
		current_scene.queue_free()
		current_scene = null

		# Make our loading screen visible again and reset some stuff
		arvr_origin.set_process_internal(true)
		arvr_camera.current = true
		$WorldEnvironment.environment = loading_screen_environment
		$LoadingScreen.progress = 0.0
		$LoadingScreen.enable_press_to_continue = false
		$LoadingScreen.follow_camera = true
		$LoadingScreen.visible = true
		emit_signal("switching_to_loading_scene")

		# Fade to visible
		$Tween.remove_all()
		$Tween.interpolate_method(self, "set_fade", 1.0, 0.0, 1.0)
		$Tween.start()
		yield($Tween, "tween_all_completed")

	# Attempt to load our scene
	resource_queue.queue_resource(p_scene_path)
	while !resource_queue.is_ready(p_scene_path):
		# wait a bit
		yield(get_tree().create_timer(0.3), "timeout")

		$LoadingScreen.progress = resource_queue.get_progress(p_scene_path)

	var new_scene : PackedScene = resource_queue.get_resource(p_scene_path)

	# Wait for user to be ready
	if prompt_for_continue:
		$LoadingScreen.enable_press_to_continue = true
		yield($LoadingScreen, "continue_pressed")

	# Fade to black
	$Tween.remove_all()
	$Tween.interpolate_method(self, "set_fade", 0.0, 1.0, 1.0)
	$Tween.start()
	yield($Tween, "tween_all_completed")

	# Hide our loading screen
	$LoadingScreen.follow_camera = false
	$LoadingScreen.visible = false

	# Turn off internal process on our ARVROrigin node, the internal process
	# of our ARVROrigin will submit its positioning data to the ARVRServer.
	# With two ARVROrigin nodes we'll get competing data.
	arvr_origin.set_process_internal(false)

	# Setup our new scene
	current_scene = new_scene.instance()
	current_scene_path = p_scene_path
	$Scene.add_child(current_scene)
	$WorldEnvironment.environment = current_scene.environment
	_add_signals(current_scene)

	# We create a small delay here to give tracking some time to update our nodes...
	yield(get_tree().create_timer(0.1), "timeout")
	current_scene.scene_loaded()
	emit_signal("scene_loaded", current_scene)

	# Fade to visible
	$Tween.remove_all()
	$Tween.interpolate_method(self, "set_fade", 1.0, 0.0, 1.0)
	$Tween.start()
	yield($Tween, "tween_all_completed")

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
		var material : ShaderMaterial = $Fade.get_surface_material(0)
		if material:
			material.set_shader_param("alpha", p_value)
		$Fade.visible = true


func _add_signals(p_scene : XRToolsSceneBase):
	p_scene.connect("request_exit_to_main_menu", self, "_on_exit_to_main_menu")
	p_scene.connect("request_load_scene", self, "_on_load_scene")
	p_scene.connect("request_reset_scene", self, "_on_reset_scene")


func _remove_signals(p_scene : XRToolsSceneBase):
	p_scene.disconnect("request_exit_to_main_menu", self, "_on_exit_to_main_menu")
	p_scene.disconnect("request_load_scene", self, "_on_load_scene")
	p_scene.disconnect("request_reset_scene", self, "_on_reset_scene")


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
