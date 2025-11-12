@tool
class_name XRToolsDesktopMovementFlight
extends XRToolsMovementProvider


## XR Tools Movement Provider for Flying
##
## This script provides flying movement for the player. The control parameters
## are intended to support a wide variety of flight mechanics.
##
## Pitch and Bearing input devices are selected which produce a "forwards"
## reference frame. The player controls (forwards/backwards and
## left/right) are applied in relation to this reference frame.
##
## The Speed Scale and Traction parameters allow primitive flight where
## the player is in direct control of their speed (in the reference frame).
## This produces an effect described as the "Mary Poppins Flying Umbrella".
##
## The Acceleration, Drag, and Guidance parameters allow for slightly more
## realisitic flying where the player can accelerate in their reference
## frame. The drag is applied against the global reference and can be used
## to construct a terminal velocity.
##
## The Guidance property attempts to lerp the players velocity into flight
## forwards direction as if the player had guide-fins or wings.
##
## The Exclusive property specifies whether flight is exclusive (no further
## physics effects after flying) or whether additional effects such as
## the default player gravity are applied.


## Signal emitted when flight starts
signal flight_started()

## Signal emitted when flight finishes
signal flight_finished()


## Movement provider order
@export var order : int = 30


## Flight toggle button
@export var flight_button : String = "ui_focus_next"
@export var input_forward : String = "ui_up"
@export var input_backward : String = "ui_down"
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"

## Flight speed from control
@export var speed_scale : float = 5.0

## Flight traction pulling flight velocity towards the controlled speed
@export var speed_traction : float = 3.0

## Flight acceleration from control
@export var acceleration_scale : float = 0.0

## Flight drag
@export var drag : float = 0.1

## Guidance effect (virtual fins/wings)
@export var guidance : float = 0.0

## If true, flight movement is exclusive preventing further movement functions
@export var exclusive : bool = true


## Flight button state
var _flight_button : bool = false


# Node references
@onready var xr_start_node = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,
	"*Staging",
	"XRToolsStaging"),"StartXR","Node")
@onready var _camera := XRHelpers.get_xr_camera(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsDesktopMovementFlight" or super(xr_name)


func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()


# Process physics movement for flight
func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Disable flying if requested, or if no controller
	if disabled or !enabled or !player_body.enabled or xr_start_node.is_xr_active():
		set_flying(false)
		return

	# Detect press of flight button
	var old_flight_button = _flight_button
	_flight_button = Input.is_action_pressed(flight_button)
	if _flight_button and !old_flight_button:
		set_flying(!is_active)

	# Skip if not flying
	if !is_active:
		return

	# Select the pitch vector
	var pitch_vector: Vector3
	# Use the vertical part of the 'head' forwards vector
	pitch_vector = -_camera.transform.basis.z.y * player_body.up_player

	# Select the bearing vector
	var bearing_vector: Vector3
	# Use the horizontal part of the 'head' forwards vector
	bearing_vector = -_camera.global_transform.basis.z \
			.slide(player_body.up_player)

	# Construct the flight bearing
	var forwards := (bearing_vector.normalized() + pitch_vector).normalized()
	var side := forwards.cross(player_body.up_player)

	# Construct the target velocity
	var input_dir = Input.get_vector(input_left, input_right, input_backward, input_forward)
	var joy_forwards :float= input_dir.y
	var joy_side :float= input_dir.x
	var heading := forwards * joy_forwards + side * joy_side

	# Calculate the flight velocity
	var flight_velocity := player_body.velocity
	flight_velocity *= 1.0 - drag * delta
	flight_velocity = flight_velocity.lerp(heading * speed_scale, speed_traction * delta)
	flight_velocity += heading * acceleration_scale * delta

	# Apply virtual guidance effect
	if guidance > 0.0:
		var velocity_forwards := forwards * flight_velocity.length()
		flight_velocity = flight_velocity.lerp(velocity_forwards, guidance * delta)

	# If exclusive then perform the exclusive move-and-slide
	if exclusive:
		player_body.velocity = player_body.move_player(flight_velocity)
		return true

	# Update velocity and return for additional effects
	player_body.velocity = flight_velocity
	return


func set_flying(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update state
	is_active = active

	# Handle state change
	if is_active:
		emit_signal("flight_started")
	else:
		emit_signal("flight_finished")


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Verify the camera
	if !XRHelpers.get_xr_camera(self):
		warnings.append("Unable to find XRCamera3D")

	# Verify the left controller
	if !XRHelpers.get_left_controller(self):
		warnings.append("Unable to find left XRController3D node")

	# Verify the right controller
	if !XRHelpers.get_right_controller(self):
		warnings.append("Unable to find left XRController3D node")

	# Return warnings
	return warnings
