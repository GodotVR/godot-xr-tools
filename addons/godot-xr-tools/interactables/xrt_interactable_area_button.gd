tool
class_name XRTInteractableAreaButton
extends Area


##
## Interactable Area Button script
##
## @desc:
##     The interactable area button detects objects and areas intering its
##     area, and moves an associated button object using a tween to animate
##     the movement.
## 


## Button pressed event
signal button_pressed(button)

## Button released event
signal button_released(button)


## Button object
export var button := NodePath()

## Displacement when pressed
export var displacement := Vector3(0.0, -0.02, 0.0)

## Displacement duration
export var duration := 0.1


# Button pressed state
var pressed := false

# Dictionary of trigger items pressing the button
var _trigger_items := {}

# Tween for animating button
var _tween: Tween

# Node references
onready var _button: Spatial = get_node(button)

# Button positions
onready var _button_up := _button.transform.origin
onready var _button_down := _button_up + displacement


# Called when the node enters the scene tree for the first time.
func _ready():
	# Construct the button animation tween
	_tween = Tween.new()
	_tween.set_name("Tween")
	add_child(_tween)
	
	# Connect area signals
	if connect("area_entered", self, "_on_button_entered"):
		push_error("Unable to connect button area signal")
	if connect("area_exited", self, "_on_button_exited"):
		push_error("Unable to connect button area signal")
	if connect("body_entered", self, "_on_button_entered"):
		push_error("Unable to connect button area signal")
	if connect("body_exited", self, "_on_button_exited"):
		push_error("Unable to connect button area signal")


# Called when an area or body enters the button area
func _on_button_entered(var item: Spatial) -> void:
	# Add to the dictionary of trigger items
	_trigger_items[item] = item

	# Detect transition to pressed
	if !pressed:
		# Update state to pressed
		pressed = true

		# Start the tween to move the button transform to the down position
		_tween.interpolate_property(_button, "transform:origin", null, _button_down, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		_tween.start()

		# Emit the pressed signal
		emit_signal("button_pressed")


# Called when an area or body exits the button area
func _on_button_exited(var item: Spatial) -> void:
	# Remove from the dictionary of triggered items
	_trigger_items.erase(item)

	# Detect transition to released
	if pressed and _trigger_items.empty():
		# Update state to released
		pressed = false

		# Start the tween to move the button transform to the up position
		_tween.interpolate_property(_button, "transform:origin", null, _button_up, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		_tween.start()

		# Emit the released signal
		emit_signal("button_released")


# Check button configuration
func _get_configuration_warning() -> String:
	# Ensure a button has been specified
	if !button:
		return "Button node to animate must be specified"

	# Ensure a valid duration
	if duration <= 0.0:
		return "Duration must be a positive number"

	return ""
