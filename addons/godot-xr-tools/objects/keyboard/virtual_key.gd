@tool
class_name XRToolsVirtualKey
extends Node2D


## Key pressed event
signal pressed

## Key released event
signal released


## Key location
@export var key_size := Vector2(32, 32) : set = _set_key_size

## Key text
@export var key_text := "" : set = _set_key_text

## Key normal color
@export var key_normal := Color(0.1, 0.1, 0.1) : set = _set_key_normal

## Key highlight color
@export var key_highlight := Color(0.2, 0.2, 0.2) : set = _set_key_highlight

## Text normal color
@export var text_normal := Color(1.0, 1.0, 1.0) : set = _set_text_normal

## Text highlight color
@export var text_highlight := Color(0.0, 0.0, 0.0) : set = _set_text_highlight

## Key highlighted
@export var highlighted := false : set = _set_highlighted


# TouchScreenButton node
var _button : TouchScreenButton

# ColorRect node
var _color : ColorRect

# Label node
var _label : Label


# Called when the node enters the scene tree for the first time.
func _ready():
	# Construct the ColorRect node
	_color = ColorRect.new()

	# Construct the Label node
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Construct the TouchScreenButton node
	_button = TouchScreenButton.new()
	_button.shape = RectangleShape2D.new()

	# Attach the nodes
	_color.add_child(_label)
	_button.add_child(_color)
	add_child(_button)

	# Handle button presses
	_button.pressed.connect(_on_button_pressed)
	_button.released.connect(_on_button_released)

	# Apply initial updates
	_update_key_size()
	_update_key_text()
	_update_highlighted()


func _on_button_pressed() -> void:
	pressed.emit()


func _on_button_released() -> void:
	released.emit()


func _set_key_size(p_key_size : Vector2) -> void:
	key_size = p_key_size
	if is_inside_tree():
		_update_key_size()


func _set_key_text(p_key_text : String) -> void:
	key_text = p_key_text
	if is_inside_tree():
		_update_key_text()


func _set_key_normal(p_key_normal : Color) -> void:
	key_normal = p_key_normal
	if is_inside_tree():
		_update_highlighted()


func _set_key_highlight(p_key_highlight : Color) -> void:
	key_highlight = p_key_highlight
	if is_inside_tree():
		_update_highlighted()


func _set_text_normal(p_text_normal : Color) -> void:
	text_normal = p_text_normal
	if is_inside_tree():
		_update_highlighted()


func _set_text_highlight(p_text_highlight : Color) -> void:
	text_highlight = p_text_highlight
	if is_inside_tree():
		_update_highlighted()


func _set_highlighted(p_highlighted : bool) -> void:
	highlighted = p_highlighted
	if is_inside_tree():
		_update_highlighted()


func _update_key_size() -> void:
	var half_size := key_size / 2

	# Set the TouchScreenButton position and shape size
	_button.position = half_size
	_button.shape.size = key_size

	# Size and position the ColorRect
	_color.size = key_size
	_color.position = -half_size

	# Size the label
	_label.size = key_size


func _update_key_text() -> void:
	_label.text = key_text


func _update_highlighted() -> void:
	# Pick colors
	var key := key_highlight if highlighted else key_normal
	var text := text_highlight if highlighted else text_normal

	# Set colors
	_color.color = key
	_label.add_theme_color_override("font_color", text)
