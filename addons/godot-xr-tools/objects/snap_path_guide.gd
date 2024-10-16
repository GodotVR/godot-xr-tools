@tool
extends Marker3D
class_name XRToolsSnapPathGuide

## XRToolsSnapRailGuide depicts a guide for [XRToolsSnapPath] to judge the length of an [XRToolsPickable].
## Add as a child node to any [XRToolsPickable], then move negatively along the Z-Axis to define a length
##     that [XRToolsSnapPath] can use to place it within its [Path3D] bounds.

var length : float:
	get:
		return abs(position.z)
