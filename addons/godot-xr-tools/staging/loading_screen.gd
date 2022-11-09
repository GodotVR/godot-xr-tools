@tool
extends Node3D

signal continue_pressed

## Introduction
#
# The loading screen is shown while the player is waiting
# while we load in a new scene.
# As the player may start in any location and likely hasn't
# put their HMD on yet when the game first starts, we place
# our splash screen far away and make it over sized.
#
# Note that we made this a tool script so you can test the
# progress bar.
#
# Note also that our background is pitch black.

## Follow camera
#
# If enabled, rotate our screen to follow the camera

@export var follow_camera : bool = true: set = set_follow_camera
@export var follow_speed : Curve

var camera : XRCamera3D

func set_follow_camera(p_enabled : bool) -> void:
	follow_camera = p_enabled
	_update_follow_camera()

func set_camera(p_camera : XRCamera3D) -> void:
	camera = p_camera
	_update_follow_camera()

func _update_follow_camera():
	if camera and !Engine.is_editor_hint():
		set_process(follow_camera)

## Splash screen
#
# Make it possible to change the splash screen we show 

@export var splash_screen : Texture2D: set = set_splash_screen

var splash_screen_material : StandardMaterial3D

func set_splash_screen(p_splash_screen : Texture2D) -> void:
	splash_screen = p_splash_screen
	_update_splash_screen()

func _update_splash_screen():
	if splash_screen_material:
		splash_screen_material.albedo_texture = splash_screen

## Progress bar
#
# We show a progress bar on screen. Note that we show
# this at a different distance to create a nice depth
# effect. 

@export_range(0.0, 1.0, 0.01) var progress : float = 0.5: set = set_progress_bar

var progress_material : ShaderMaterial

func set_progress_bar(p_progress : float) -> void:
	progress = p_progress
	_update_progress_bar()

func _update_progress_bar():
	if progress_material:
		progress_material.set_shader_parameter("progress", progress)

## Press to continue
#
# When toggled we show our press to continue message and enable our trigger

@export var enable_press_to_continue : bool = false: set = set_enable_press_to_continue

func set_enable_press_to_continue(p_enable : bool) -> void:
	enable_press_to_continue = p_enable
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
	
	_update_follow_camera()

func _process(delta):
	if Engine.is_editor_hint():
		return

	if !camera:
		return

	var camera_dir = camera.global_transform.basis.z
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

	# Do rotation based on the curve
	global_transform.basis = global_transform.basis.rotated(cross, follow_speed.sample_baked(angle / PI) * delta).orthonormalized()
