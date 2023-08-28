@tool
class_name XRToolsVirtualKeyChar
extends XRToolsVirtualKey


## Godot scan-code text
@export var scan_code_text := ""

## Unicode character
@export var unicode := 0

## Shift modifier
@export var shift_modifier := false


# Keyboard associated with this button
var _keyboard : XRToolsVirtualKeyboard2D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Call the base
	super()

	# Find the keyboard
	_keyboard = XRTools.find_xr_ancestor(
		self,
		"*",
		"XRToolsVirtualKeyboard2D")

	# Handle button presses
	pressed.connect(_on_pressed)
	released.connect(_on_released)


# Handler for button pressed
func _on_pressed() -> void:
	highlighted = true
	if _keyboard:
		_keyboard.on_key_pressed(scan_code_text, unicode, shift_modifier)


# Handler for button released
func _on_released() -> void:
	highlighted = false
