@tool
class_name XRToolsStartXR
extends Node


## XRTools Start XR Class
##
## This class supports both the OpenXR and WebXR interfaces, and handles
## the initialization of the interface as well as reporting when the user
## starts and ends the VR session.
##
## For OpenXR this class also supports passthrough on compatible devices such
## as the Meta Quest 1 and 2.


## This signal is emitted when XR becomes active. For OpenXR this corresponds
## with the 'openxr_focused_state' signal which occurs when the application
## starts receiving XR input, and for WebXR this corresponds with the
## 'session_started' signal.
signal xr_started

## This signal is emitted when XR ends. For OpenXR this corresponds with the
## 'openxr_visible_state' state which occurs when the application has lost
## XR input focus, and for WebXR this corresponds with the 'session_ended'
## signal.
signal xr_ended


## If true, the XR interface is automatically initialized
@export var auto_initialize : bool = true

## Adjusts the pixel density on the rendering target
@export var render_target_size_multiplier : float = 1.0

## If true, the XR passthrough is enabled (OpenXR only)
@export var enable_passthrough : bool = false: set = _set_enable_passthrough

## Physics rate multiplier compared to HMD frame rate
@export var physics_rate_multiplier : int = 1

## If non-zero, specifies the target refresh rate
@export var target_refresh_rate : float = 0


## Current XR interface
var xr_interface : XRInterface

## XR active flag
var xr_active : bool = false

# Current refresh rate
var _current_refresh_rate : float = 0


# Handle auto-initialization when ready
func _ready() -> void:
	if !Engine.is_editor_hint() and auto_initialize:
		initialize()


## Initialize the XR interface
func initialize() -> bool:
	# Check for OpenXR interface
	xr_interface = XRServer.find_interface('OpenXR')
	if xr_interface:
		return _setup_for_openxr()

	# Check for WebXR interface
	xr_interface = XRServer.find_interface('WebXR')
	if xr_interface:
		return _setup_for_webxr()

	# No XR interface
	xr_interface = null
	print("No XR interface detected")
	return false


# Check for configuration issues
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if physics_rate_multiplier < 1:
		warnings.append("Physics rate multiplier should be at least 1x the HMD rate")

	return warnings


# Perform OpenXR setup
func _setup_for_openxr() -> bool:
	print("OpenXR: Configuring interface")

	# Set the render target size multiplier - must be done befor initializing interface
	# NOTE: Only implemented in Godot 4.1+
	if "render_target_size_multiplier" in xr_interface:
		xr_interface.render_target_size_multiplier = render_target_size_multiplier

	# Initialize the OpenXR interface
	if not xr_interface.is_initialized():
		print("OpenXR: Initializing interface")
		if not xr_interface.initialize():
			push_error("OpenXR: Failed to initialize")
			return false

	# Connect the OpenXR events
	xr_interface.connect("session_begun", _on_openxr_session_begun)
	xr_interface.connect("session_visible", _on_openxr_visible_state)
	xr_interface.connect("session_focussed", _on_openxr_focused_state)

	# Check for passthrough
	if enable_passthrough and xr_interface.is_passthrough_supported():
		enable_passthrough = xr_interface.start_passthrough()

	# Disable vsync
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# Switch the viewport to XR
	get_viewport().use_xr = true

	# Report success
	return true


# Handle OpenXR session ready
func _on_openxr_session_begun() -> void:
	print("OpenXR: Session begun")

	# Get the reported refresh rate
	_current_refresh_rate = xr_interface.get_display_refresh_rate()
	if _current_refresh_rate > 0:
		print("OpenXR: Refresh rate reported as ", str(_current_refresh_rate))
	else:
		print("OpenXR: No refresh rate given by XR runtime")

	# Pick a desired refresh rate
	var desired_rate := target_refresh_rate if target_refresh_rate > 0 else _current_refresh_rate
	var available_rates : Array = xr_interface.get_available_display_refresh_rates()
	if available_rates.size() == 0:
		print("OpenXR: Target does not support refresh rate extension")
	elif available_rates.size() == 1:
		print("OpenXR: Target supports only one refresh rate")
	elif desired_rate > 0:
		print("OpenXR: Available refresh rates are ", str(available_rates))
		var rate = _find_closest(available_rates, desired_rate)
		if rate > 0:
			print("OpenXR: Setting refresh rate to ", str(rate))
			xr_interface.set_display_refresh_rate(rate)
			_current_refresh_rate = rate

	# Pick a physics rate
	var active_rate := _current_refresh_rate if _current_refresh_rate > 0 else 144.0
	var physics_rate := int(round(active_rate * physics_rate_multiplier))
	print("Setting physics rate to ", physics_rate)
	Engine.physics_ticks_per_second = physics_rate


# Handle OpenXR visible state
func _on_openxr_visible_state() -> void:
	# Report the XR ending
	if xr_active:
		print("OpenXR: XR ended (visible_state)")
		xr_active = false
		emit_signal("xr_ended")


# Handle OpenXR focused state
func _on_openxr_focused_state() -> void:
	# Report the XR starting
	if not xr_active:
		print("OpenXR: XR started (focused_state)")
		xr_active = true
		emit_signal("xr_started")


# Handle changes to the enable_passthrough property
func _set_enable_passthrough(p_new_value : bool) -> void:
	# Save the new value
	enable_passthrough = p_new_value

	# Only actually start our passthrough if our interface has been instanced
	# if not this will be delayed until initialise is successfully called.
	if xr_interface:
		if enable_passthrough:
			# unset enable_passthrough if we can't start it.
			enable_passthrough = xr_interface.start_passthrough()
		else:
			xr_interface.stop_passthrough()


# Perform WebXR setup
func _setup_for_webxr() -> bool:
	print("WebXR: Configuring interface")

	# Connect the WebXR events
	xr_interface.connect("session_supported", _on_webxr_session_supported)
	xr_interface.connect("session_started", _on_webxr_session_started)
	xr_interface.connect("session_ended", _on_webxr_session_ended)
	xr_interface.connect("session_failed", _on_webxr_session_failed)

	# WebXR currently has no means of querying the refresh rate, so use
	# something sufficiently high
	Engine.physics_ticks_per_second = 144

	# If the viewport is already in XR mode then we are done.
	if get_viewport().use_xr:
		return true

	# This returns immediately - our _webxr_session_supported() method
	# (which we connected to the "session_supported" signal above) will
	# be called sometime later to let us know if it's supported or not.
	xr_interface.is_session_supported("immersive-vr")

	# Report success
	return true


# Handle WebXR session supported check
func _on_webxr_session_supported(session_mode: String, supported: bool) -> void:
	if session_mode == "immersive-vr":
		if supported:
			# WebXR supported - show canvas on web browser to enter WebVR
			$EnterWebXR.visible = true
		else:
			OS.alert("Your web browser doesn't support VR. Sorry!")


# Called when the WebXR session has started successfully
func _on_webxr_session_started() -> void:
	print("WebXR: Session started")

	# Hide the canvas and switch the viewport to XR
	$EnterWebXR.visible = false
	get_viewport().use_xr = true

	# Report the XR starting
	xr_active = true
	emit_signal("xr_started")


# Called when the user ends the immersive VR session
func _on_webxr_session_ended() -> void:
	print("WebXR: Session ended")

	# Show the canvas and switch the viewport to non-XR
	$EnterWebXR.visible = true
	get_viewport().use_xr = false

	# Report the XR ending
	xr_active = false
	emit_signal("xr_ended")


# Called when the immersive VR session fails to start
func _on_webxr_session_failed(message: String) -> void:
	OS.alert("Unable to enter VR: " + message)
	$EnterWebXR.visible = true


# Handle the Enter VR button on the WebXR browser
func _on_enter_webxr_button_pressed() -> void:
	# Configure the WebXR interface
	xr_interface.session_mode = 'immersive-vr'
	xr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
	xr_interface.required_features = 'local-floor'
	xr_interface.optional_features = 'bounded-floor'

	# Initialize the interface. This should trigger either _on_webxr_session_started
	# or _on_webxr_session_failed
	if not xr_interface.initialize():
		OS.alert("Failed to initialize WebXR")


# Find the closest value in the array to the target
func _find_closest(values : Array, target : float) -> float:
	# Return 0 if no values
	if values.size() == 0:
		return 0.0

	# Find the closest value to the target
	var best : float = values.front()
	for v in values:
		if abs(target - v) < abs(target - best):
			best = v

	# Return the best value
	return best
