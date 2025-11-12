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
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsGroundPhysics"


# This method verifies the ground physics has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify physics specified
	if !physics:
		warnings.append("Physics must be specified")
	elif !physics is XRToolsGroundPhysicsSettings:
		warnings.append("Physics must be an XRToolsGroundPhysicsSettings")

	return warnings

# Get the physics from a ground physics node
static func get_physics(
		node: XRToolsGroundPhysics,
		default: XRToolsGroundPhysicsSettings) -> XRToolsGroundPhysicsSettings:
	return node.physics as XRToolsGroundPhysicsSettings if node else default
