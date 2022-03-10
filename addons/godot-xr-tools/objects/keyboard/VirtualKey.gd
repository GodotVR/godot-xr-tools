extends Button

## Godot scan-code text
export var scan_code_text := ""

## Unicode character
export var unicode := 0

## Shift modifier
export var shift_modifier := false

func _ready():
	# Find the VirtualKeyboard parent
	var keyboard = _get_virtual_keyboard()
	if keyboard:
		connect("button_down", keyboard, "on_key_pressed", [scan_code_text, unicode, shift_modifier])

# Get our virtual keyboard parent
func _get_virtual_keyboard() -> VirtualKeyboard2D:
	# Get parent node and start walking up the tree
	var node = get_parent()
	while node:
		# Check if the node is the keyboard
		if node is VirtualKeyboard2D:
			return node

		# Step up the tree
		node = node.get_parent()
	
	# No virtual keyboard found
	return null
