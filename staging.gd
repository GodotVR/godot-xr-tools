extends Spatial

## Introduction
#
# Staging is our main containing scene that we load on startup.
#
# This scene sets up our XR environment. We do this by including
# the First Person Controller from our OpenXR plugin. 
# However, we don't use these in the rest of our demos.
#
# Furthermore this scene has our loading screen and an anchor
# point into which we load the actual scene we wish the user
# to interact with. We will be loading individual demos to 
# demonstrate different techniques.
#
# If you are creating a game with multiple levels or environments
# you may wish to copy the approach we take here, it is a good 
# framework for such games.
#
# If you are creating a game with a single level you may wish to
# simplify things. Check out the demo included in the source
# repository for the OpenXR plugin and then use the techniques
# explained in individual demos found here.

## WorldEnvironment
#
# You will note that our staging scene has a world environment
# node included. Godot does not have a mechanism for having
# multiple world environments in our scene and marking one as
# active which makes it impractical to embed these in our demo
# scenes. Instead we will obtain the environment from our demo
# scene and manage it here. Our world environment at the start
# belongs to our loading screen and we need to keep a copy.

onready var loading_screen_environment = $WorldEnvironment.environment 

## Fade
#
# Our fade object allows us to black out the screen for transitions.
# Note that our AABB is set to HUGE so it should always be rendered
# unless hidden.

func set_fade(p_value : float):
	if p_value == 0.0:
		$Fade.visible = false
	else:
		var material : ShaderMaterial = $Fade.get_surface_material(0)
		if material:
			material.set_shader_param("alpha", p_value)
		$Fade.visible = true

## Scene swapping
#
# These functions control our scene swapping
#
# Note ResourceQueue is an autoloaded script, see project settings.

var current_scene : SceneBase
var current_scene_path : String

func _on_exit_to_main_menu():
	load_scene("res://scenes/main_menu/main_menu_level.tscn")

func _on_load_scene(p_scene_path : String):
	load_scene(p_scene_path)

func _add_signals(p_scene : SceneBase):
	p_scene.connect("exit_to_main_menu", self, "_on_exit_to_main_menu")
	p_scene.connect("load_scene", self, "_on_load_scene")

func _remove_signals(p_scene : SceneBase):
	p_scene.disconnect("exit_to_main_menu", self, "_on_exit_to_main_menu")
	p_scene.disconnect("load_scene", self, "_on_load_scene")

func load_scene(p_scene_path : String):
	# Check if it's already loaded...
	if p_scene_path == current_scene_path:
		return

	if current_scene:
		# Start by unloading our scene
		
		# First remove signals
		_remove_signals(current_scene)
		
		# Fade to black
		$Tween.remove_all()
		$Tween.interpolate_method(self, "set_fade", 0.0, 1.0, 1.0)
		$Tween.start()
		yield($Tween, "tween_all_completed")
		
		# Now we remove our scene
		current_scene.scene_exiting()
		$Scene.remove_child(current_scene)
		current_scene.queue_free()
		current_scene = null
		
		# Make our loading screen visible again and reset some stuff
		$FPController.set_process_internal(true)
		$FPController/ARVRCamera.current = true
		$WorldEnvironment.environment = loading_screen_environment
		$LoadingScreen.progress = 0.0
		$LoadingScreen.enable_press_to_continue = false
		$LoadingScreen.follow_camera = true
		$LoadingScreen.visible = true
		
		# Fade to visible
		$Tween.remove_all()
		$Tween.interpolate_method(self, "set_fade", 1.0, 0.0, 1.0)
		$Tween.start()
		yield($Tween, "tween_all_completed")
	
	# Attempt to load our scene
	ResourceQueue.queue_resource(p_scene_path)
	while !ResourceQueue.is_ready(p_scene_path):
		# wait one second
		yield(get_tree().create_timer(1.0), "timeout")
		
		$LoadingScreen.progress = ResourceQueue.get_progress(p_scene_path)
	
	var new_scene : PackedScene = ResourceQueue.get_resource(p_scene_path)
	
	# Wait for user to be ready
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
	
	# Turn off internal process on our FPController, the internal process
	# of our ARVROrigin will submit its positioning data to the ARVRServer.
	# With two ARVROrigin nodes we'll get competing data.
	$FPController.set_process_internal(false)
	
	# Setup our new scene
	current_scene = new_scene.instance()
	current_scene_path = p_scene_path
	$Scene.add_child(current_scene)
	$WorldEnvironment.environment = current_scene.environment
	_add_signals(current_scene)
	
	# We create a small delay here to give tracking some time to update our nodes...
	yield(get_tree().create_timer(0.1), "timeout")
	current_scene.scene_loaded()
	
	# Fade to visible
	$Tween.remove_all()
	$Tween.interpolate_method(self, "set_fade", 1.0, 0.0, 1.0)
	$Tween.start()
	yield($Tween, "tween_all_completed")

## interface

func _ready():
	# Start our resource loader
	ResourceQueue.start()
	
	# We start by loading our main level scene
	load_scene("res://scenes/main_menu/main_menu_level.tscn")
