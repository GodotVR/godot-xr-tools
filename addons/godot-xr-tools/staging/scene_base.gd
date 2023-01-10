class_name XRToolsSceneBase
extends Spatial

## Introduction
#
# This is our base scene for all our levels.
# It ensures that we have all bits in place to load
# our scene into our staging scene.

# Emit this signal to let staging know we should return to our menu scene
signal exit_to_main_menu

# Emit this signal to let staging know we should load the specified scene
signal load_scene

## Environment
#
# Here we set the environment we need to set as our world environment
# once our scene is loaded.

export var environment : Environment

## Interface


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsSceneBase" or .is_class(name)


func center_player_on(p_transform : Transform):
	# In order to center our player so the players feet are at the location
	# indicated by p_transform, and having our player looking in the required
	# direction, we must offset this transform using the cameras transform.

	# So we get our current camera transform in local space
	var camera_transform = $ARVROrigin/ARVRCamera.transform

	# We obtain our view direction and zero out our height
	var view_direction = camera_transform.basis.z
	view_direction.y = 0

	# Now create the transform that we will use to offset our input with
	var transform : Transform
	transform = transform.looking_at(-view_direction, Vector3.UP)
	transform.origin = camera_transform.origin
	transform.origin.y = 0

	# And now update our origin point
	$ARVROrigin.global_transform = (p_transform * transform.inverse()).orthonormalized()

func scene_loaded():
	# Called after scene is loaded

	# Make sure our camera becomes the current camera
	$ARVROrigin/ARVRCamera.current = true

	# Center our player on our origin point
	# Note, this means you can place the ARVROrigin point in the start
	# position where you want the player to spawn, even if the player is
	# physically halfway across the room.
	center_player_on($ARVROrigin.global_transform)

func scene_visible():
	# Called after the scene becomes fully visible
	pass

func scene_pre_exiting():
	# Called before we start fading out and removing our scene
	pass

func scene_exiting():
	# called right before we remove this scene
	pass

