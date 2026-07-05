@tool
extends Node3D

## XR Tools Loading Screen
##
## The loading screen is shown while the player is waiting while we load in a
## new scene.[br][br]
##
## As the player may start in any location and likely hasn't put their HMD on
## by the time the game first starts, we place our splash screen far away and
## make it over sized.[br][br]
##
## [b]Note[/b]: this is a tool script, so you can test the progress bar.
## We show this at a different distance to create a nice depth effect.[br][br]
##
## [b]Note[/b]: our background is pitch black.


## Emitted when the user presses 'Continue'
signal continue_pressed


## Whether the screen follows the camera
@export var follow_camera := true: set = set_follow_camera

## Curve for following the camera
@export var follow_speed: Curve

## Splash screen texture
@export var splash_screen: Texture2D: set = set_splash_screen

## Percentage of the scene that has loaded
@export_range(0.0, 1.0, 0.01) var progress := 0.5: set = set_progress_bar

## Whether the continue message is shown or the progress bar is visible.
@export var enable_press_to_continue := false:
	set = set_enable_press_to_continue


# Camera to track
var _camera: XRCamera3D

# Mesh instance for the progress bar
var _progress_bar: MeshInstance3D

# Splash screen material
var _splash_screen_material: StandardMaterial3D

# Progress material
var _progress_material: ShaderMaterial


func _ready() -> void:
	# Get the nodes
	_progress_bar = $ProgressBar

	# Get materials
	_splash_screen_material = $SplashScreen.get_surface_override_material(0)
	_progress_material = _progress_bar.mesh.surface_get_material(0)

	# Perform initial update
	_update_splash_screen()
	_update_progress_bar()
	_update_enable_press_to_continue()
	_update_follow_camera()


func _process(delta: float) -> void:
	# Skip if in editor
	if Engine.is_editor_hint():
		return

	# Skip if no camera to track
	if not _camera:
		return

	# Get the camera direction (horizontal only)
	var camera_dir := _camera.global_transform.basis.z
	camera_dir.y = 0.0
	camera_dir = camera_dir.normalized()

	# Get the loading screen direction
	var loading_screen_dir := global_transform.basis.z

	# Get the angle
	var angle := loading_screen_dir.signed_angle_to(camera_dir, Vector3.UP)
	if angle == 0:
		return

	# Do rotation based on the curve
	global_transform.basis = global_transform.basis.rotated(
			Vector3.UP * sign(angle),
			follow_speed.sample_baked(abs(angle) / PI) * delta,
	).orthonormalized()


## Sets the camera to track
func set_camera(p_camera: XRCamera3D) -> void:
	_camera = p_camera
	_update_follow_camera()


## Sets whether the continue message is shown or the progress bar is visible
func set_enable_press_to_continue(p_enable : bool) -> void:
	enable_press_to_continue = p_enable
	_update_enable_press_to_continue()


## Sets whether to follow a camera
func set_follow_camera(p_enabled: bool) -> void:
	follow_camera = p_enabled
	_update_follow_camera()


## Sets the percentage of the scene that has loaded
func set_progress_bar(p_progress: float) -> void:
	progress = p_progress
	_update_progress_bar()


## Set the texture of the splash screen
func set_splash_screen(p_splash_screen: Texture2D) -> void:
	splash_screen = p_splash_screen
	_update_splash_screen()


func _on_HoldButton_pressed() -> void:
	continue_pressed.emit()


func _update_enable_press_to_continue() -> void:
	if is_inside_tree():
		_progress_bar.visible = not enable_press_to_continue
		$PressToContinue.visible = enable_press_to_continue
		$PressToContinue/HoldButton.enabled = enable_press_to_continue


func _update_follow_camera() -> void:
	if _camera and not Engine.is_editor_hint():
		set_process(follow_camera)


func _update_progress_bar() -> void:
	if _progress_material:
		_progress_material.set_shader_parameter("progress", progress)


func _update_splash_screen() -> void:
	if _splash_screen_material:
		_splash_screen_material.albedo_texture = splash_screen
