@tool
class_name XRToolsPhysicsHand
extends XRToolsHand


## XR Tools Physics Hand Script
##
## This script extends from the standard [XRToolsHand] and adds settings to
## manage collision and group settings for all [XRToolsHandPhysicsBone] nodes
## attached to the hand.


# Default hand bone layer of 18:player-hand
const DEFAULT_LAYER := 0b0000_0000_0000_0010_0000_0000_0000_0000


## Collision layer applied to all [XRToolsHandPhysicsBone] children.
##
## This is used to set physics collision layers for every bone in a hand.
## Additionally [XRToolsHandPhysicsBone] nodes can specify additional
## bone-specific collision layers - for example to give the fore-finger bone
## additional collision capabilities.
@export_flags_3d_physics var collision_layer : int = DEFAULT_LAYER

## Bone collision margin applied to all [XRToolsHandPhysicsBone] children.
##
## This is used for fine-tuning the collision margins for all
## [XRToolsHandPhysicsBone] children in the hand.
@export var margin : float = 0.004

## Group applied to all [XRToolsHandPhysicsBone] children.
##
## This is used to set groups for every bone in the hand. Additionally
## [XRToolsHandPhysicsBone] nodes can specify additional bone-specific groups.
@export var bone_group : String = ""


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsPhysicsHand" or super(xr_name)
