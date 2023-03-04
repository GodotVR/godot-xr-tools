extends Node3D

@export_node_path("XRCamera3D") var camera : NodePath

# Called when the node enters the scene tree for the first time.
func _ready():
	var camera_node = get_node_or_null(camera)
	if camera_node:
		var scene = $Screen/Viewport2Din3D.get_scene_instance()
		if scene:
			var settings_ui = scene.get_node_or_null("UserSettingsUI")
			if settings_ui:
				settings_ui.camera = camera_node.get_path()
