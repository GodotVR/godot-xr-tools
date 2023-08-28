@tool
class_name DemoStaging
extends XRToolsStaging

## Introduction
#
# This is an example of using the staging system in XRTools
# to create an environment in which you can background load
# scenes and switch between them.
#
# There is also some example code here on how to react to
# the player taking their headset on/off.
#
# The primary function here is to trigger the
# "Press to continue" dialog when switching scenes.
# We do not want to enter our just loaded scene when the
# player is still thumbling around putting their headset on
# so if we detect they hadn't put their headset on yet
# when we were scene switching, we prompt the user.
#
# Finally this shows an example of how to react to pause
# a game. This is not implemented in this demo (yet) but
# note that most XR runtimes stop giving us controller
# tracking data at this point.

var scene_is_loaded : bool = false

# Stores which hand the control pad is bound to
var control_pad_hand : String = "LEFT"


func _ready() -> void:
	# In Godot 4 we must now manually call our super class ready function
	super()


func _on_Staging_scene_loaded(_scene, _user_data):
	# We only show the press to continue the first time we load a scene
	# to give the player time to put their headset on.
	prompt_for_continue = false
	scene_is_loaded = true


func _on_Staging_scene_exiting(_scene, _user_data):
	# We no longer have an active scene
	scene_is_loaded = false


func _on_Staging_xr_started():
	# We get the 'xr_started' signal when the user puts on their headset,
	# or returns from the system menus.
	# If the user did so while we were already scene switching
	# we leave our prompt for continue on,
	# else we turn our prompt for continue off.
	if scene_is_loaded:
		# No longer need our prompt
		prompt_for_continue = false

		# This would be a good moment to unpause your game


func _on_Staging_xr_ended():
	# We get the 'xr_ended' whenever the player removes their headset (or goes
	# into the menu system).
	#
	# If the user doesn't put their headset on again before we load a
	# new scene, we'll want to show the prompt so we don't load the
	# next scene in while the player is still adjusting their position
	prompt_for_continue = true

	if scene_is_loaded:
		# This would be a good moment to pause your game
		pass
