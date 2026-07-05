@tool
class_name XRToolsSceneBase
extends Node3D

## XR Tools Scene Base Class
##
## This is our base scene for all our levels.  It ensures that we have all bits
## in place to load our scene into our staging scene.[br][br]
##
## Developers can customize scene transitions by extending from this class and
## overriding the [method scene_loaded] behavior.


## Emitted when requesting the staging transition to the main-menu scene.[br][br]
## [b]Note[/b]: Developers should use [method exit_to_main_menu], rather than
## emitting this signal directly.
signal request_exit_to_main_menu

## Emitted when requesting the staging transition to the specified scene, with
## the [param user_data] parameter passed through staging to the new scenes.[br][br]
## [b]Note[/b]: Developers should use [method load_scene], rather than emitting
## this signal directly.
signal request_load_scene(p_scene_path: String, user_data: Variant)

## Emitted when requesting the staging to reload this scene, with the
## [param user_data] parameter is passed through staging to the new scenes.[br][br]
## [b]Note[/b]: Developers should use [method reset_scene], rather than emitting
## this signal directly
signal request_reset_scene(user_data: Variant)

## Emitted when requesting the staging to quit the XR experience.[br][br]
## [b]Note[/b]: Developers should use [method quit], rather than emitting this
## signal directly.
signal request_quit


# This file contains methods with parameters that are unused, however they are
# documented and intended to be overridden in derived classes. As such, unused
# parameter warnings need to be disabled.
#
# warning-ignore:unused_parameter
# gdlint:disable=unused-argument

var _camera: XRCamera3D
var _xr_origin: XROrigin3D


func _ready() -> void:
	_camera = $XROrigin3D/XRCamera3D
	_xr_origin = $XROrigin3D


## Centers the player on the [param p_transform] transform.
func center_player_on(p_transform: Transform3D) -> void:
	# In order to center our player so the players feet are at the location
	# indicated by p_transform, and having our player looking in the required
	# direction, we must offset this transform using the cameras transform.

	# So we get our current camera transform in local space
	var camera_transform: Transform3D = _camera.transform

	# We obtain our view direction and zero out our height
	var view_direction: Vector3 = camera_transform.basis.z
	view_direction.y = 0

	# Now create the transform that we will use to offset our input with
	var transform: Transform3D
	transform = transform.looking_at(-view_direction, Vector3.UP)
	transform.origin = camera_transform.origin
	transform.origin.y = 0

	# And now update our origin point
	_xr_origin.global_transform = (
			p_transform * transform.inverse()
	).orthonormalized()

	# If we have a player body, we need to set its starting position too.
	var player_body := XRToolsPlayerBody.find_instance(_xr_origin)
	if player_body:
		player_body.global_transform = p_transform


## Transitions to the main menu scene. The default implementation sends the
## [signal request_exit_to_main_menu] signal.[br][br]
##
## Custom scene classes can override this function to add their logic, but
## should usually call this super method.
func exit_to_main_menu() -> void:
	request_exit_to_main_menu.emit()


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsSceneBase"


## Transitions to the specified scene. The default implementation sends the
## [signal request_load_scene].
##
## Custom scene classes can override this function to add their logic, but
## should usually call this super method.
##
## The [param user_data] parameter is passed to the new scene, and can be used
## to relay information through the transition. The default behavior of
## [method scene_loaded] will attempt to interpret it as  a spawn-point for the
## player as node-name, Vector3, or Transform3D.
##
## See [method scene_loaded] for options to provide advanced scene-transition
## functionality.
func load_scene(p_scene_path: String, user_data: Variant = null) -> void:
	request_load_scene.emit(p_scene_path, user_data)


## Resets the current scene. The default implementation sends the
## [signal request_reset_scene], which triggers a reload of the current scene.[br][br]
##
## Custom scene classes can override this method to implement faster reset
## logic than is performed by the brute-force scene-reload performed by
## staging.[br][br]
##
## Any [param user_data] provided is passed into the new scene.
func reset_scene(user_data: Variant = null) -> void:
	request_reset_scene.emit(user_data)


## Immediately before this scene is unloaded.[br][br]
##
## The [param user_data] parameter is an optional parameter passed in when the
## scene transition is requested.
func scene_exiting(user_data = null) -> void:
	# Called right before we remove this scene
	pass


## When the scene is loaded, but before it becomes visible.[br][br]
##
## The [param user_data] parameter is an optional parameter passed in when the
## scene is loaded - usually from the previous scene. By default, the
## user_data can be a [String] spawn-point node-name, [Vector3], [Transform3D],
## an object with a 'get_spawn_position' method, or null to spawn at the scenes
## [XROrigin3D] location.
##
## Advanced scene-transition functionality can be implemented by overriding this
## method and calling the super() with any desired spawn transform. This could
## come from a field of an advanced user_data class-object, or from a game-state
## singleton.
func scene_loaded(user_data: Variant = null) -> void:
	# Make sure our camera becomes the current camera
	_camera.current = true
	_xr_origin.current = true

	# Start by assuming the user_data contains spawn position information.
	var spawn_position: Variant = user_data

	# If the user_data is an object with a 'get_spawn_position' method, then
	# call it (with this [XRToolsSceneBase], allowing it to inspect the scene
	# if necessary) and use the return value as the spawn position information.
	if (
			typeof(user_data) == TYPE_OBJECT
			and user_data.has_method("get_spawn_position")
	):
		spawn_position = user_data.get_spawn_position(self)

	# Get the spawn [Transform3D] by inspecting the spawn position value for
	# standard types of spawn position information:
	# - null to use the standard XROrigin3D location
	# - String name of a Node3D to spawn at
	# - Vector3 to spawn at
	# - Transform3D to spawn at
	var spawn_transform := _xr_origin.global_transform
	match typeof(spawn_position):
		TYPE_STRING: # Name of Node3D to spawn at
			var node := find_child(spawn_position)
			if node is Node3D:
				spawn_transform = node.global_transform

		TYPE_VECTOR3: # Vector3 to spawn at (rotation comes from XROrigin3D)
			spawn_transform.origin = spawn_position

		TYPE_TRANSFORM3D: # Transform3D spawn location
			spawn_transform = spawn_position

	# Center the player on the spawn location
	center_player_on(spawn_transform)


## Before the start of transition from this scene to a new scene.[br][br]
##
## The [param user_data] parameter is an optional parameter passed in when the
## scene transition is requested.
func scene_pre_exiting(user_data: Variant = null) -> void:
	# Called before we start fading out and removing our scene
	pass


## When the scene becomes fully visible to the user.[br][br]
##
## The [param user_data] parameter is an optional parameter passed in when the
## scene is loaded - usually from the previous scene.
func scene_visible(user_data: Variant = null) -> void:
	# Called after the scene becomes fully visible
	pass


## Quits the XR experience. The default implementation sends the
## [signal request_quit] signal, which triggers the XR experience to end.[br][br]
##
## Custom scene classes can override this method to add their logic.
func quit() -> void:
	request_quit.emit()
