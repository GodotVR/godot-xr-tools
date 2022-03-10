class_name VirtualKeyboard2D
extends CanvasLayer

# Enumeration of keyboard view modes
enum KEYBOARD_MODE {
	LOWER_CASE,		# Lower-case keys mode
	UPPER_CASE,		# Upper-case keys mode
	ALTERNATE		# Alternate keys mode
}

# Shift button down
var _shift_down := false

# Caps button down
var _caps_down := false

# Alt button down
var _alt_down := false

# Current keyboard mode
var _mode: int = KEYBOARD_MODE.LOWER_CASE


# Handle key pressed from VirtualKey
func on_key_pressed(scan_code_text: String, unicode: int, shift: bool):
	# Find the scan code
	var scan_code := OS.find_scancode_from_string(scan_code_text)

	# Create the InputEventKey
	var input := InputEventKey.new()
	input.physical_scancode = scan_code
	input.unicode = unicode if unicode else scan_code
	input.pressed = true
	input.scancode = scan_code
	input.shift = shift

	# Dispatch the input event
	Input.parse_input_event(input)

	# Pop any temporary shift key
	if _shift_down:
		$Background/Standard/ToggleShift.set_pressed_no_signal(false)
		_shift_down = false
		_update_visible()

func on_shift_toggle(button_pressed):
	# Update toggle keys
	$Background/Standard/ToggleCaps.set_pressed_no_signal(false)
	$Background/Standard/ToggleAlt.set_pressed_no_signal(false)
	_shift_down = button_pressed
	_caps_down = false
	_alt_down = false
	_update_visible()

# Handle caps-lock toggle
func on_caps_toggle(button_pressed):
	# Update toggle keys
	$Background/Standard/ToggleShift.set_pressed_no_signal(false)
	$Background/Standard/ToggleAlt.set_pressed_no_signal(false)
	_shift_down = false
	_caps_down = button_pressed
	_alt_down = false
	_update_visible()

func on_alt_toggle(button_pressed):
	# Update toggle keys
	$Background/Standard/ToggleShift.set_pressed_no_signal(false)
	$Background/Standard/ToggleCaps.set_pressed_no_signal(false)
	_shift_down = false
	_caps_down = false
	_alt_down = button_pressed
	_update_visible()

# Update switching the visible case keys
func _update_visible():
	# Evaluate the new mode
	var new_mode: int
	if _alt_down:
		new_mode = KEYBOARD_MODE.ALTERNATE
	elif _shift_down or _caps_down:
		new_mode = KEYBOARD_MODE.UPPER_CASE
	else:
		new_mode = KEYBOARD_MODE.LOWER_CASE

	# Skip if no change
	if new_mode == _mode:
		return

	# Update the visible mode
	_mode = new_mode
	$Background/LowerCase.visible = _mode == KEYBOARD_MODE.LOWER_CASE
	$Background/UpperCase.visible = _mode == KEYBOARD_MODE.UPPER_CASE
	$Background/Alternate.visible = _mode == KEYBOARD_MODE.ALTERNATE
