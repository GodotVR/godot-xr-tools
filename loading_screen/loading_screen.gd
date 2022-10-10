@tool
extends Node3D

signal continue_pressed

## Introduction
#
# The loading screen is shown while the player is waiting
# while we load in a new scene.
# As the player may start in any location and likely hasn't
# put their HMD checked yet when the game first starts, we place
# our splash screen far away and make it over sized.
#
# Note that we made this a tool script so you can test the
# progress bar.
#
# Note also that our background is pitch black.

## Follow camera
#
# If enabled, rotate our screen to follow the camera

@export var follow_camera : bool = true:
	set(new_value):
		follow_camera = new_value
		_update_follow_camera()

@export_node_path(XRCamera3D) var camera : NodePath

@export var follow_speed : Curve

var camera_node : XRCamera3D

func _update_follow_camera():
	if camera_node and !Engine.is_editor_hint():
		set_process(follow_camera)

## Splash screen
#
# Make it possible to change the splash screen we show 

@export var splash_screen : Texture2D:
	set(new_value):
		splash_screen = new_value
		_update_splash_screen()

var splash_screen_material : StandardMaterial3D

func _update_splash_screen():
	if splash_screen_material:
		splash_screen_material.albedo_texture = splash_screen

## Progress bar
#
# We show a progress bar checked screen. Note that we show
# this at a different distance to create a nice depth
# effect. 

@export_range(0.0, 1.0, 0.01) var progress : float = 0.5:
	set(new_value):
		progress = new_value
		_update_progress_bar()

var progress_material : ShaderMaterial

func _update_progress_bar():
	if progress_material:
		progress_material.set_shader_parameter("progress", progress)

## Press to continue
#
# When toggled we show our press to continue message and enable our trigger

@export var enable_press_to_continue : bool = false:
	set(new_value):
		enable_press_to_continue = new_value
		_update_enable_press_to_continue()

func _update_enable_press_to_continue():
	if is_inside_tree():
		$ProgressBar.visible = !enable_press_to_continue
		$PressToContinue.visible = enable_press_to_continue
		$PressToContinue/HoldButton.enabled = enable_press_to_continue

func _on_HoldButton_pressed():
	# our Hold button will already be marked as disabled, we'll leave the rest as is...
	
	# Call down the tree
	emit_signal("continue_pressed")

## Interface

func _ready():
	# Our initial property values get set before we're ready,
	# so now that we're ready, start applying them...
	splash_screen_material = $SplashScreen.get_surface_override_material(0)
	_update_splash_screen()
	
	progress_material = $ProgressBar.mesh.surface_get_material(0)
	_update_progress_bar()
	
	_update_enable_press_to_continue()
	
	camera_node = get_node_or_null(camera)
	_update_follow_camera()

func _process(delta):
	if Engine.is_editor_hint():
		return

	var camera_dir = camera_node.global_transform.basis.z
	camera_dir.y = 0.0
	camera_dir = camera_dir.normalized()

	var loading_screen_dir = global_transform.basis.z

	# Calculate the rotation-axis to rotate the screen in front of the camera
	var cross = loading_screen_dir.cross(camera_dir)
	if cross.is_equal_approx(Vector3.ZERO):
		return

	# Calculate the angle to rotate the screen in front of the camera
	cross = cross.normalized()
	var dot = loading_screen_dir.dot(camera_dir)
	var angle = acos(dot)

	# Do rotation based checked the curve
	global_transform.basis = global_transform.basis.rotated(cross, follow_speed.sample_baked(angle / PI) * delta).orthonormalized()
