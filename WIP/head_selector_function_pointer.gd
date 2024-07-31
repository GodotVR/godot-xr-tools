extends XRToolsSceneBase

func _ready() -> void:
	$Options.position = $XROrigin3D/XRCamera3D.position
	$Options.rotation.y = $XROrigin3D/XRCamera3D.rotation.y
	enable_buttons()

func reactivate_buttons() -> void:
	await get_tree().create_timer(1).timeout
	enable_buttons()


func enable_buttons() -> void:
	$Options/OptionALabel.modulate = Color("white")
	$Options/OptionBLabel.modulate = Color("white")


func _on_area_3da_pointer_event(event: Variant) -> void:
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		$Options/OptionALabel.modulate = Color("red")
		reactivate_buttons()


func _on_area_3db_pointer_event(event: Variant) -> void:
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		$Options/OptionBLabel.modulate = Color("red")
		reactivate_buttons()
