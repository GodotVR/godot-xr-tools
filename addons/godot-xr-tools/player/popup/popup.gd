@tool
@icon("res://addons/godot-xr-tools/editor/icons/node.svg")
class_name XRToolsPopup
extends Node3D


## XR Tools Popup Script
##
## This script manages a popup user interface for the player. Popup interfaces
## are usually constructed with Viewport 2D in 3D interfaces that have their
## collision layers set to 24:popup-ui.
##
## The popup can be made visible either by external control of the visible
## state, or by the player pressing the controller popup buttons which are
## usually tied to the menu buttons.
##
## The script will by default override any function pointers on the players
## hands to collide with 24:popup-ui while the popup is visible.


## Default override collision mask of 24:popup-ui
const DEFAULT_MASK := 0b0000_0000_1000_0000_0000_0000_0000_0000


@export_group("Input")

## Left controller popup action
@export var left_popup_action := "menu_button"

## Right controller popup action
@export var right_popup_action := "menu_button"

## Pointer collision mask to set when popup active (0 = don't override)
@export_flags_3d_physics var pointer_mask := DEFAULT_MASK

@export_group("Following")

## Angle to start following
@export var angle_start := 45.0

## Angle to stop following
@export var angle_stop := 3.0

## Distance to start following
@export var distance_start := 0.3

## Distance to stop following
@export var distance_stop := 0.05

## Following rate
@export var follow_rate := 1.0

## Following acceleration
@export var follow_acceleration := 1.0


var _left_pointer_mask := -1
var _right_pointer_mask := -1
var _following := false
var _following_rate := 0.0


@onready var _camera := XRHelpers.get_xr_camera(self)
@onready var _left_controller := XRHelpers.get_left_controller(self)
@onready var _right_controller := XRHelpers.get_right_controller(self)
@onready var _left_pointer := XRToolsFunctionPointer.find_left(self)
@onready var _right_pointer := XRToolsFunctionPointer.find_right(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPopup"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Skip if in editor
	if Engine.is_editor_hint():
		return

	# Connect controller buttons
	if _left_controller:
		_left_controller.button_pressed.connect(_on_left_button_pressed)
	if _right_controller:
		_right_controller.button_pressed.connect(_on_right_button_pressed)

	# Turn off visibility
	visibility_changed.connect(_on_visibility_changed)
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Skip if in editor
	if Engine.is_editor_hint():
		return

	# Get the forward transform
	var target := _forward_transform()

	# Measure the angle and update following flag
	var angle := rad_to_deg(target.basis.z.angle_to(basis.z))
	var distance := target.origin.distance_to(position)
	if angle > angle_start or distance > distance_start:
		_following = true
	elif angle < angle_stop and distance < distance_stop:
		_following = false
		_following_rate = 0.0


	# Follow if enabled
	if _following:
		# Update the applied following rate
		_following_rate = min(
			_following_rate + follow_acceleration * delta,
			follow_rate)

		# Interpolate to the target transform
		transform = transform.interpolate_with(
			target,
			_following_rate * delta)


# This method checks the configuration of the XRToolsPopup
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if get_parent() as XROrigin3D == null:
		warnings.append("Popup must be a direct child of the XROrigin3D node")

	return warnings


# This method is called when the user presses a button on the left controller
func _on_left_button_pressed(button_name : String) -> void:
	if button_name == left_popup_action:
		visible = !visible


# This method is called when a user presses a button on the right controller
func _on_right_button_pressed(button_name : String) -> void:
	if button_name == right_popup_action:
		visible = !visible


# This method is called when the visibility changes
func _on_visibility_changed() -> void:
	# Handle transition to visible
	if visible:
		# Snap in front of player and enable tracking-processing
		transform = _forward_transform()
		set_process(true)

		# Override the left pointer mask
		if _left_pointer and pointer_mask:
			_left_pointer_mask = _left_pointer.collision_mask
			_left_pointer.collision_mask = pointer_mask

		# Override the right pointer mask
		if _right_pointer and pointer_mask:
			_right_pointer_mask = _right_pointer.collision_mask
			_right_pointer.collision_mask = pointer_mask
	else:
		# Disable tracking
		set_process(false)

		# Restore the left pointer mask
		if _left_pointer and _left_pointer_mask >= 0:
			_left_pointer.collision_mask = _left_pointer_mask
			_left_pointer_mask = -1

		# Restore the right pointer mask
		if _right_pointer and _right_pointer_mask >= 0:
			_right_pointer.collision_mask = _right_pointer_mask
			_right_pointer_mask = -1


# This method calculates the perfect forward transform
func _forward_transform() -> Transform3D:
	# Get the camera transform and basis
	var camera_transform := _camera.transform
	var camera_basis := camera_transform.basis

	# Calculate the new Y vector (aligned with origin Y)
	var new_y := Vector3.UP

	# Calculate the camera Z
	var camera_z := camera_basis.z
	var camera_elevation := new_y.dot(camera_z)

	# Calculate the new Z vector (chosen from best camera Z axis)
	var new_z : Vector3
	if camera_elevation > 0.75: # Looking down, use Y+
		new_z = camera_basis.y.slide(new_y).normalized()
	elif camera_elevation < -0.75: # Looking up, use Y-
		new_z = -camera_basis.y.slide(new_y).normalized()
	else:
		new_z = camera_z.slide(new_y).normalized()

	# Calculate the new X
	var new_x := new_y.cross(new_z)

	# Return the forward transform
	return Transform3D(new_x, new_y, new_z, camera_transform.origin)
