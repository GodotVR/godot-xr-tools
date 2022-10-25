extends SceneBase


enum Pointer {
	LEFT = 0,
	RIGHT = 1
}

var pointer_left_or_right = Pointer.RIGHT


func _set_pointer_enabled():
	$ARVROrigin/LeftHand/FunctionPointer.enabled = pointer_left_or_right == Pointer.LEFT
	$ARVROrigin/RightHand/FunctionPointer.enabled = pointer_left_or_right == Pointer.RIGHT


# Called when the node enters the scene tree for the first time.
func _ready():
	_set_pointer_enabled()


func _on_LeftHand_button_pressed(button):
	if pointer_left_or_right == Pointer.RIGHT and button == $ARVROrigin/LeftHand/FunctionPointer.active_button:
		# switch to left
		pointer_left_or_right = Pointer.LEFT
		_set_pointer_enabled()


func _on_RightHand_button_pressed(button):
	if pointer_left_or_right == Pointer.LEFT and button == $ARVROrigin/RightHand/FunctionPointer.active_button:
		# switch to right
		pointer_left_or_right = Pointer.RIGHT
		_set_pointer_enabled()
