@tool
class_name XRToolsGroundPhysics
extends Node


## XR Tools Ground Physics Data
##
## This script override the default ground physics settings of the
## [XRToolsPlayerBody] when they are standing on a specific type of ground.
##
## In order to override the ground physics properties, the user must add a
## ground physics node to the object the player would stand on, then
## enable the appropriate flags and provide new values.


## XRToolsGroundPhysicsSettings to apply
@export var physics : XRToolsGroundPhysicsSettings


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsGroundPhysics"


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
static func get_physics(
		node: XRToolsGroundPhysics,
		default: XRToolsGroundPhysicsSettings) -> XRToolsGroundPhysicsSettings:
	return node.physics as XRToolsGroundPhysicsSettings if node else default
