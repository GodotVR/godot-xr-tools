tool
class_name XRToolsGroundPhysics
extends Node


##
## Ground Physics Data
##
## @desc:
##     This script override the default ground physics settings of the
##     player when they are standing on a specific type of ground.
##
##     In order to override the ground physics properties, the user must add a
##     ground physics node to the object the player would stand on, then
##     enable the appropriate flags and provide new values.
##

## XRToolsGroundPhysicsSettings to apply - can only be typed in Godot 4+
export var physics : Resource


# This method verifies the ground physics has a valid configuration.
func _get_configuration_warning():
	# Verify physics specified
	if !physics:
		return "Physics must be specified"

	# Verify physics is of the correct type
	if !physics is XRToolsGroundPhysicsSettings:
		return "Physics must be an XRToolsGroundPhysicsSettings"

	# Report valid
	return ""

# Get the physics from a ground physics node
static func get_physics(node: XRToolsGroundPhysics, default: XRToolsGroundPhysicsSettings) -> XRToolsGroundPhysicsSettings:
	return node.physics as XRToolsGroundPhysicsSettings if node else default
