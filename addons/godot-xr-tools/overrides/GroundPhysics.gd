tool
class_name GroundPhysics
extends Node


##
## Ground Physics Data
##
## @desc:
##     This script works with the GroundPhysics asset override the default
##     ground physics settings of the player when they are standing on a
##     specific type of ground.
##
##     In order to override the ground physics properties, the user must add a
##     GroundPhysics node to the object the player would stand on, then
##     enable the appropriate flags and provide new values.
##

## GroundPhysicsSettings to apply - can only be typed in Godot 4+
export (Resource) var physics

# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Verify physics specified
	if !physics:
		return "Physics must be specified"

	# Verify physics is of the correct type
	if !physics is GroundPhysicsSettings:
		return "Physics must be a GroundPhysicsSettings"

	# Report valid
	return ""
