tool
class_name XRToolsExampleRumbleControls
extends Node

##
##  Controls for demonstrating the rumble manager
##

export var event_name := ""

export(int, "Both", "Left", "Right") var hand := 0

export var magnitude_min := 0.1

export var magnitude_max := 0.5

export(NodePath) var magnitude_slider_path := NodePath()

export var duration_min := 0.1

export var duration_max := 1.0

export(NodePath) var duration_slider_path := NodePath()

export(NodePath) var activate_button_path := NodePath()

export(NodePath) var off_button_path := NodePath()

export(NodePath) var label_path := NodePath()

export(NodePath) var rumble_path := NodePath()

var magnitude_slider: XRToolsInteractableSlider

var magnitude := 0.05

var duration_slider: XRToolsInteractableSlider

# Indefinite by default
var duration_sec := -1.0

var activate_button: XRToolsInteractableAreaButton

var off_button: XRToolsInteractableAreaButton

var label: RichTextLabel

var label_form: String

var rumble: XRToolsRumble


func _ready():
	# Use node's name if none set
	if event_name == "":
		event_name = name

	# Find and wire required nodes
	rumble = get_node(rumble_path)

	label = get_node(label_path)
	if is_instance_valid(label):
		label_form = label.bbcode_text

	magnitude_slider = get_node(magnitude_slider_path)
	# warning-ignore:return_value_discarded
	magnitude_slider.connect("slider_moved", self, "magnitude_slider_moved")
	magnitude_slider_moved(magnitude_slider.slider_position)

	activate_button = get_node(activate_button_path)
	# warning-ignore:return_value_discarded
	activate_button.connect("button_pressed", self, "activate")

	#Find optional nodes if set

	if not duration_slider_path.is_empty():
		duration_slider = get_node(duration_slider_path)
		# warning-ignore:return_value_discarded
		duration_slider.connect("slider_moved", self, "duration_slider_moved")
		duration_slider_moved(duration_slider.slider_position)

	if not off_button_path.is_empty():
		off_button = get_node(off_button_path)
		# warning-ignore:return_value_discarded
		off_button.connect("button_pressed", self, "deactivate")


# This method verifies the vignette has a valid configuration.
# Specifically it checks the following:
# - ARVROrigin is a parent
# - ARVRCamera is our parent
func _get_configuration_warning():
	var errors = ""

	if not get_node_or_null(rumble_path):
		errors += "Cannot find rumble manager! \n"

	if not get_node_or_null(label_path):
		errors += "Cannot find description label! \n"

	if get_node_or_null(magnitude_slider_path) == null:
		errors += "Magnitude Slider path is invalid! \n"

	if get_node_or_null(activate_button_path) == null:
		errors += "Activate Button path is invalid! \n"

	if not duration_slider_path.is_empty() and get_node_or_null(duration_slider_path) == null:
		errors += "Duration Slider path is invalid! \n"

	if not off_button_path.is_empty() and get_node_or_null(off_button_path) == null:
		errors += "Off Button path is invalid! \n"

	return errors


func magnitude_slider_moved(value: float) -> void:
	var slider_range = magnitude_slider.slider_limit_max - magnitude_slider.slider_limit_min
	var magnitude_range = magnitude_max - magnitude_min

	magnitude = value - magnitude_slider.slider_limit_min
	magnitude *= magnitude_range / slider_range
	magnitude += magnitude_min  # add minimum

	_update_label()


func duration_slider_moved(value: float) -> void:
	var slider_range = duration_slider.slider_limit_max - duration_slider.slider_limit_min
	var duration_range = duration_max - duration_min

	duration_sec = value - duration_slider.slider_limit_min
	duration_sec *= duration_range / slider_range
	duration_sec += duration_min  # add minimum

	_update_label()


func _update_label() -> void:
	if not is_instance_valid(label) or Engine.editor_hint:
		return
	var insert_text = "%s/%ss" % [magnitude, duration_sec] if duration_sec > 0 else "%s" % magnitude
	label.bbcode_text = label_form % insert_text


func activate() -> void:
	var duration_ms := int(duration_sec * 1000)
	rumble.set(event_name, magnitude, hand, duration_ms)


func deactivate() -> void:
	rumble.remove(event_name)
