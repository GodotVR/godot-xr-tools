class_name XRToolsPhysicsHand
extends XRToolsHand


##
## XR Physics Hand Script
##
## @desc:
##     This script extends the standard godot-xr-tools hand script to add
##     collision and group settings for all physics bones in the hand.
##


## Collision layer for all bones in the hand
@export_flags_3d_physics var collision_layer : int = 1 << 17

## Bone collision margin
@export var margin : float = 0.004

## Bone group for all bones in the hand
@export var bone_group : String = ""
