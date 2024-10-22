@tool
class_name XRToolsSnapPathGuide
extends Marker3D


## XRToolsSnapRailGuide depicts a guide for [XRToolsSnapPath] to judge the
## length of an [XRToolsPickable], helping place pickables within its bounds.
## Add as a child node to any [XRToolsPickable], then move negatively along
## the Z-Axis to define a length.


var length : float:
	get:
		return abs(position.z)
