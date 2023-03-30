@tool
class_name XRToolsSceneBaseCharacterBody
extends XRToolsSceneBase

# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsSceneBaseCharacterBody"

func center_player_on(p_transform : Transform3D):
	$XRToolsCharacterBody.center_player_on(p_transform)

func scene_loaded():
	$XRToolsCharacterBody.center_player_on($XRToolsCharacterBody.global_transform)
