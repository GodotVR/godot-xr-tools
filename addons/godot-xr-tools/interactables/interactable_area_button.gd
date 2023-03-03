@tool
class_name XRToolsInteractableAreaButton
extends Area3D


## XR Tools Interactable Area Button script
##
## The interactable area button detects objects and areas intering its
## area, and moves an associated button object using a tween to animate
## the movement.


## Button pressed event
signal button_pressed(button)

## Button released event
signal button_released(button)


## Button object
@export var button := NodePath()

## Displacement when pressed
@export var displacement : Vector3 = Vector3(0.0, -0.02, 0.0)

## Displacement duration
@export var duration : float = 0.1


## If true, the button is pressed
var pressed : bool = false

## Dictionary of trigger items pressing the button
var _trigger_items := {}

## Tween for animating button
var _tween: Tween


# Node references
@onready var _button: Node3D = get_node(button)

# Button positions
@onready var _button_up := _button.transform.origin
@onready var _button_down := _button_up + displacement


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableAreaButton"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect area signals
	if area_entered.connect(_on_button_entered):
		push_error("Unable to connect button area signal")
	if area_exited.connect(_on_button_exited):
		push_error("Unable to connect button area signal")
	if body_entered.connect(_on_button_entered):
		push_error("Unable to connect button area signal")
	if body_exited.connect(_on_button_exited):
		push_error("Unable to connect button area signal")


# Called when an area or body enters the button area
func _on_button_entered(item: Node3D) -> void:
	# Add to the dictionary of trigger items
	_trigger_items[item] = item

	# Detect transition to pressed
	if !pressed:
		# Update state to pressed
		pressed = true

		# Kill the current tween
		if _tween:
			_tween.kill()

		# Construct the button animation tween
		_tween = get_tree().create_tween()
		_tween.set_trans(Tween.TRANS_LINEAR)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_button, "position", _button_down, duration)

		# Emit the pressed signal
		button_pressed.emit(self)


# Called when an area or body exits the button area
func _on_button_exited(item: Node3D) -> void:
	# Remove from the dictionary of triggered items
	_trigger_items.erase(item)

	# Detect transition to released
	if pressed and _trigger_items.is_empty():
		# Update state to released
		pressed = false

		# Kill the current tween
		if _tween:
			_tween.kill()

		# Construct the button animation tween
		_tween = get_tree().create_tween()
		_tween.set_trans(Tween.TRANS_LINEAR)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_button, "position", _button_up, duration)

		# Emit the released signal
		button_released.emit(self)


# Check button configuration
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Ensure a button has been specified
	if not get_node_or_null(button):
		warnings.append("Button node to animate must be specified")

	# Ensure a valid duration
	if duration <= 0.0:
		warnings.append("Duration must be a positive number")

	return warnings
