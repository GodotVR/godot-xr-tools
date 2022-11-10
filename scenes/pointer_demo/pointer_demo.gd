extends XRToolsSceneBase


enum Pointer {
	LEFT = 0,
	RIGHT = 1
}

var pointer_left_or_right = Pointer.RIGHT


func _set_pointer_enabled():
	$XROrigin3D/LeftHand/FunctionPointer.enabled = pointer_left_or_right == Pointer.LEFT
	$XROrigin3D/RightHand/FunctionPointer.enabled = pointer_left_or_right == Pointer.RIGHT


# Called when the node enters the scene tree for the first time.
func _ready():
	_set_pointer_enabled()


func _on_LeftHand_button_pressed(button):
	if pointer_left_or_right == Pointer.RIGHT and button == $XROrigin3D/LeftHand/FunctionPointer.active_button_action:
		# switch to left
		pointer_left_or_right = Pointer.LEFT
		_set_pointer_enabled()


func _on_RightHand_button_pressed(button):
	if pointer_left_or_right == Pointer.LEFT and button == $XROrigin3D/RightHand/FunctionPointer.active_button_action:
		# switch to right
		pointer_left_or_right = Pointer.RIGHT
		_set_pointer_enabled()
