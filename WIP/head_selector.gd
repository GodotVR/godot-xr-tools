extends XRToolsSceneBase

@onready var raycast = $XROrigin3D/XRCamera3D/RayCast3D
@onready var hold_button_a = $Options/OptionALabel/HoldButtonA
@onready var hold_button_b = $Options/OptionBLabel/HoldButtonB


func _ready() -> void:
	$Options.position = $XROrigin3D/XRCamera3D.position
	$Options.rotation.y = $XROrigin3D/XRCamera3D.rotation.y
	enable_buttons()


func _process(delta: float) -> void:
	var new_target : Node3D
	if raycast.is_colliding():
		new_target = raycast.get_collider()
		if new_target.name == "Area3DA" and hold_button_a.enabled:
			hold_button_a.external_pressed = true
			hold_button_b.external_pressed = false
			$Options/OptionALabel.modulate = Color("yellow")
			$Options/OptionBLabel.modulate = Color("white")
		elif new_target.name == "Area3DB" and hold_button_b.enabled:
			hold_button_b.external_pressed = true
			hold_button_a.external_pressed = false
			$Options/OptionBLabel.modulate = Color("yellow")
			$Options/OptionALabel.modulate = Color("white")
	else:
		hold_button_a.external_pressed = false
		hold_button_b.external_pressed = false
		$Options/OptionALabel.modulate = Color("white")
		$Options/OptionBLabel.modulate = Color("white")
	pass

func reactivate_buttons() -> void:
	await get_tree().create_timer(1).timeout
	enable_buttons()


func enable_buttons() -> void:
	hold_button_a.enabled = true
	hold_button_b.enabled = true
	$Options/OptionALabel.modulate = Color("white")
	$Options/OptionBLabel.modulate = Color("white")


func _on_hold_button_a_pressed() -> void:
	print("A pressed")
	$Options/OptionALabel.modulate = Color("red")
	hold_button_a.enabled = false
	reactivate_buttons()


func _on_hold_button_b_pressed() -> void:
	print("B pressed")
	$Options/OptionBLabel.modulate = Color("red")
	hold_button_b.enabled = false
	reactivate_buttons()
