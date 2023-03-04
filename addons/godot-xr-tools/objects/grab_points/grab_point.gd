class_name XRToolsGrabPoint
extends Marker3D


## XR Tools Grab Point Base Script
##
## This script is the base for all grab points. Pickable object extending from
## [XRToolsPickable] can have numerous grab points to control where the object
## is grabbed from.


## If true, the grab point is enabled for grabbing
@export var enabled : bool = true


## Test if a grabber can grab by this grab-point
func can_grab(_grabber : Node) -> bool:
	return enabled
