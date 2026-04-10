@tool
class_name XRToolsVirtualKeyboard2D
extends CanvasLayer


## Enumeration of keyboard view modes
enum KeyboardMode {
	LOWER_CASE,		## Lower-case keys mode
	UPPER_CASE,		## Upper-case keys mode
	ALTERNATE		## Alternate keys mode
}


# Whether the Shift button is pressed down
var _shift_down := false

# Whether the Caps Lock button is pressed down
var _caps_down := false

# Whether the Alt button is pressed down
var _alt_down := false

# Current keyboard mode
var _mode: int = KeyboardMode.LOWER_CASE

# Viewport node to push input to
var _viewport: Viewport = null


func _ready() -> void:
	# This should be the SubViewport in the virtual keyboard's Viewport2Din3D
	var vp: Viewport = get_viewport()

	if is_instance_valid(vp.get_parent()):
		_viewport = vp.get_parent().get_viewport()


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsVirtualKeyboard2D"


## Handles key presses from [XRToolsVirtualKey]
func on_key_pressed(scan_code_text: String, unicode: int, shift: bool) -> void:
	# Find the scan code
	var scan_code := OS.find_keycode_from_string(scan_code_text)

	# Create the InputEventKey
	var input := InputEventKey.new()
	input.physical_keycode = scan_code
	input.unicode = unicode if unicode else scan_code
	input.pressed = true
	input.keycode = scan_code
	input.shift_pressed = shift

	# Dispatch the input event
	Input.parse_input_event(input)

	# If the viewport of the virtual keyboard's Viewport2Din3D isn't the
	# root viewport, we should pass the input event to that viewport as well
	if _viewport != get_tree().root and _viewport != null:
		_viewport.push_input(input)

	# Pop any temporary shift key
	if _shift_down:
		_shift_down = false
		_update_visible()


func _on_toggle_alt_pressed() -> void:
	# Update toggle keys
	_alt_down = not _alt_down
	_shift_down = false
	_caps_down = false
	_update_visible()


func _on_toggle_caps_pressed() -> void:
	# Update toggle keys
	_caps_down = not _caps_down
	_shift_down = false
	_alt_down = false
	_update_visible()


func _on_toggle_shift_pressed() -> void:
	# Update toggle keys
	_shift_down = not _shift_down
	_caps_down = false
	_alt_down = false
	_update_visible()


# Updates switching the visible case keys
func _update_visible() -> void:
	# Ensure the control buttons are set correctly
	$Background/Standard/ToggleShift.highlighted = _shift_down
	$Background/Standard/ToggleCaps.highlighted = _caps_down
	$Background/Standard/ToggleAlt.highlighted = _alt_down

	# Evaluate the new mode
	var new_mode: int
	if _alt_down:
		new_mode = KeyboardMode.ALTERNATE
	elif _shift_down or _caps_down:
		new_mode = KeyboardMode.UPPER_CASE
	else:
		new_mode = KeyboardMode.LOWER_CASE

	# Skip if no change
	if new_mode == _mode:
		return

	# Update the visible mode
	_mode = new_mode
	$Background/LowerCase.visible = _mode == KeyboardMode.LOWER_CASE
	$Background/UpperCase.visible = _mode == KeyboardMode.UPPER_CASE
	$Background/Alternate.visible = _mode == KeyboardMode.ALTERNATE
