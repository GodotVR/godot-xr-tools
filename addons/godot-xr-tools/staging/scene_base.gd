@tool
class_name XRToolsSceneBase
extends Node3D


## XR Tools Scene Base Class
##
## This is our base scene for all our levels.  It ensures that we have all bits
## in place to load our scene into our staging scene.
##
## Developers can customize scene transitions by extending from this class and
## overriding the [method scene_loaded] behavior.


## This signal is used to request the staging transition to the main-menu
## scene. Developers should use [method exit_to_main_menu] rather than
## emitting this signal directly.
signal request_exit_to_main_menu

## This signal is used to request the staging transition to the specified
## scene. Developers should use [method load_scene] rather than emitting
## this signal directly.
##
## The [param user_data] parameter is passed through staging to the new scenes.
signal request_load_scene(p_scene_path, user_data)

## This signal is used to request the staging reload this scene. Developers
## should use [method reset_scene] rather than emitting this signal directly.
##
## The [param user_data] parameter is passed through staging to the new scenes.
signal request_reset_scene(user_data)

## This signal is used to request the staging quit the XR experience. Developers
## should use [method quit] rather than emitting this signal directly.
signal request_quit


# This file contains methods with parameters that are unused; however they are
# documented and intended to be overridden in derived classes. As such unused
# parameter warnings need to be disabled.
#
# warning-ignore:unused_parameter
# gdlint:disable=unused-argument


## Interface

func _ready() -> void:
	pass


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsSceneBase"


## This method center the player on the [param p_transform] transform.
func center_player_on(p_transform : Transform3D):
	# In order to center our player so the players feet are at the location
	# indicated by p_transform, and having our player looking in the required
	# direction, we must offset this transform using the cameras transform.

	# So we get our current camera transform in local space
	var camera_transform = $XROrigin3D/XRCamera3D.transform

	# We obtain our view direction and zero out our height
	var view_direction = camera_transform.basis.z
	view_direction.y = 0

	# Now create the transform that we will use to offset our input with
	var transform : Transform3D
	transform = transform.looking_at(-view_direction, Vector3.UP)
	transform.origin = camera_transform.origin
	transform.origin.y = 0

	# And now update our origin point
	$XROrigin3D.global_transform = (p_transform * transform.inverse()).orthonormalized()


## This method is called when the scene is loaded, but before it becomes visible.
##
## The [param user_data] parameter is an optional parameter passed in when the
## scene is loaded - usually from the previous scene. By default the
## user_data can be a [String] spawn-point node-name, [Vector3], [Transform3D],
## an object with a 'get_spawn_position' method, or null to spawn at the scenes
## [XROrigin3D] location.
##
## Advanced scene-transition functionality can be implemented by overriding this
## method and calling the super() with any desired spawn transform. This could
## come from a field of an advanced user_data class-object, or from a game-state
## singleton.
func scene_loaded(user_data = null):
	# Called after scene is loaded

	# Make sure our camera becomes the current camera
	$XROrigin3D/XRCamera3D.current = true
	$XROrigin3D.current = true

	# Start by assuming the user_data contains spawn position information.
	var spawn_position = user_data

	# If the user_data is an object with a 'get_spawn_position' method then
	# call it (with this [XRToolsSceneBase] allowing it to inspect the scene
	# if necessary) and use the return value as the spawn position information.
	if typeof(user_data) == TYPE_OBJECT and user_data.has_method("get_spawn_position"):
		spawn_position = user_data.get_spawn_position(self)

	# Get the spawn [Transform3D] by inspecting the spawn position value for
	# standard types of spawn position information:
	# - null to use the standard XROrigin3D location
	# - String name of a Node3D to spawn at
	# - Vector3 to spawn at
	# - Transform3D to spawn at
	var spawn_transform : Transform3D = $XROrigin3D.global_transform
	match typeof(spawn_position):
		TYPE_STRING: # Name of Node3D to spawn at
			var node = find_child(spawn_position)
			if node is Node3D:
				spawn_transform = node.global_transform

		TYPE_VECTOR3: # Vector3 to spawn at (rotation comes from XROrigin3D)
			spawn_transform.origin = spawn_position

		TYPE_TRANSFORM3D: # Transform3D spawn location
			spawn_transform = spawn_position

	# Center the player on the spawn location
	center_player_on(spawn_transform)


## This method is called when the scene becomes fully visible to the user.
##
## The [param user_data] parameter is an optional parameter passed in when the
## scene is loaded - usually from the previous scene.
func scene_visible(user_data = null):
	# Called after the scene becomes fully visible
	pass


## This method is called before the start of transition from this scene to a
## new scene.
##
## The [param user_data] parameter is an optional parameter passed in when the
## scene transition is requested.
func scene_pre_exiting(user_data = null):
	# Called before we start fading out and removing our scene
	pass


## This method is called immediately before this scene is unloaded.
##
##
## The [param user_data] parameter is an optional parameter passed in when the
## scene transition is requested.
func scene_exiting(user_data = null):
	# called right before we remove this scene
	pass


## Transition to the main menu scene
##
## This function is used to transition to the main menu scene. The default
## implementation sends the [signal request_exit_to_main_menu].
##
## Custom scene classes can override this function to add their logic, but
## should usually call this super method.
func exit_to_main_menu() -> void:
	emit_signal("request_exit_to_main_menu")


## This function is used to transition to the specified scene. The default
## implementation sends the [signal request_load_scene].
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
func load_scene(p_scene_path : String, user_data = null) -> void:
	emit_signal("request_load_scene", p_scene_path, user_data)


## This function is used to reset the current scene. The default
## implementation sends the [signal request_reset_scene] which triggers
## a reload of the current scene.
##
## Custom scene classes can override this method to implement faster reset
## logic than is performed by the brute-force scene-reload performed by
## staging.
##
## Any [param user_data] provided is passed into the new scene.
func reset_scene(user_data = null) -> void:
	emit_signal("request_reset_scene", user_data)


## This function is used to quit the XR experience. The default
## implementation sends the [signal request_quit] which triggers
## the XR experience to end.
##
## Custom scene classes can override this method to add their logic.
func quit() -> void:
	emit_signal("request_quit")
