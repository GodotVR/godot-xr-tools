@tool
class_name XRToolsStartXR
extends Node


## XRTools Start XR Class
##
## This class supports both the OpenXR and WebXR interfaces, and handles
## the initialization of the interface as well as reporting when the user
## starts and ends the VR session.
##
## For OpenXR this class also supports passthrough on compatible devices.


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

## This signal is emitted if XR fails to initialize.
signal xr_failed_to_initialize


## XR active flag
static var _xr_active : bool = false


## Optional viewport to control
@export var viewport : Viewport

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

## XR frame rate
var xr_frame_rate : float = 0

# Is a WebXR is_session_supported query running
var _webxr_session_query : bool = false


# Handle auto-initialization when ready
func _ready() -> void:
	if !Engine.is_editor_hint():
		_initialize()


## Initialize the XR interface
func _initialize() -> bool:
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
	xr_failed_to_initialize.emit()
	return false


## End the XR experience
func end_xr() -> void:
	# For WebXR drop the interactive experience and go back to the web page
	if xr_interface is WebXRInterface:
		# Uninitialize the WebXR interface
		xr_interface.uninitialize()
		return

	# Terminate the application
	get_tree().quit()


## Test if XR is active
static func is_xr_active() -> bool:
	return _xr_active


## Get the XR viewport
func get_xr_viewport() -> Viewport:
	# Use the specified viewport if set
	if viewport:
		return viewport

	# Use the default viewport
	return get_viewport()


# Check for configuration issues
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if physics_rate_multiplier < 1:
		warnings.append("Physics rate multiplier should be at least 1x the HMD rate")

	return warnings


# Perform OpenXR setup
func _setup_for_openxr() -> bool:
	print("OpenXR: Configuring interface")

	# Set the render target size multiplier
	xr_interface.render_target_size_multiplier = render_target_size_multiplier

	# Initialize the OpenXR interface
	if not xr_interface.is_initialized():
		print("OpenXR: Initializing interface")
		if not xr_interface.initialize():
			push_error("OpenXR: Failed to initialize")
			xr_failed_to_initialize.emit()
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
	get_xr_viewport().transparent_bg = enable_passthrough
	get_xr_viewport().use_xr = true

	# Report success
	return true


# Handle OpenXR session ready
func _on_openxr_session_begun() -> void:
	print("OpenXR: Session begun")

	# Set the XR frame rate
	_set_xr_frame_rate()


# Handle OpenXR visible state
func _on_openxr_visible_state() -> void:
	# Report the XR ending
	if _xr_active:
		print("OpenXR: XR ended (visible_state)")
		_xr_active = false
		xr_ended.emit()


# Handle OpenXR focused state
func _on_openxr_focused_state() -> void:
	# Report the XR starting
	if not _xr_active:
		print("OpenXR: XR started (focused_state)")
		_xr_active = true
		xr_started.emit()


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

		# Update transparent background
		get_xr_viewport().transparent_bg = enable_passthrough


# Perform WebXR setup
func _setup_for_webxr() -> bool:
	print("WebXR: Configuring interface")

	# Connect the WebXR events
	xr_interface.connect("session_supported", _on_webxr_session_supported)
	xr_interface.connect("session_started", _on_webxr_session_started)
	xr_interface.connect("session_ended", _on_webxr_session_ended)
	xr_interface.connect("session_failed", _on_webxr_session_failed)

	# If the viewport is already in XR mode then we are done.
	if get_xr_viewport().use_xr:
		return true

	# This returns immediately - our _webxr_session_supported() method
	# (which we connected to the "session_supported" signal above) will
	# be called sometime later to let us know if it's supported or not.
	_webxr_session_query = true
	xr_interface.is_session_supported('immersive-ar' if enable_passthrough else 'immersive-vr')

	# Report success
	return true


# Handle WebXR session supported check
func _on_webxr_session_supported(session_mode: String, supported: bool) -> void:
	# Skip if not running session-query
	if not _webxr_session_query:
		return

	# Clear the query flag
	_webxr_session_query = false

	# Report if not supported
	if not supported:
		OS.alert("Your web browser doesn't support " + session_mode + ". Sorry!")
		xr_failed_to_initialize.emit()
		return

	# WebXR supported - show canvas on web browser to enter WebVR
	$EnterWebXR.visible = true


# Called when the WebXR session has started successfully
func _on_webxr_session_started() -> void:
	print("WebXR: Session started")

	# Set the XR frame rate
	_set_xr_frame_rate()

	# Hide the canvas and switch the viewport to XR
	$EnterWebXR.visible = false
	get_xr_viewport().transparent_bg = enable_passthrough
	get_xr_viewport().use_xr = true

	# Report the XR starting
	_xr_active = true
	xr_started.emit()


# Called when the user ends the immersive VR session
func _on_webxr_session_ended() -> void:
	print("WebXR: Session ended")

	# Show the canvas and switch the viewport to non-XR
	$EnterWebXR.visible = true
	get_xr_viewport().transparent_bg = false
	get_xr_viewport().use_xr = false

	# Report the XR ending
	_xr_active = false
	xr_ended.emit()


# Called when the immersive VR session fails to start
func _on_webxr_session_failed(message: String) -> void:
	OS.alert("Unable to enter VR: " + message)
	$EnterWebXR.visible = true


# Handle the Enter VR button on the WebXR browser
func _on_enter_webxr_button_pressed() -> void:
	# Configure the WebXR interface
	xr_interface.session_mode = 'immersive-ar' if enable_passthrough else 'immersive-vr'
	xr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
	xr_interface.required_features = 'local-floor'
	xr_interface.optional_features = 'bounded-floor'

	# Add hand-tracking if enabled in the project settings
	if ProjectSettings.get_setting_with_override("xr/openxr/extensions/hand_tracking"):
		xr_interface.optional_features += ", hand-tracking"

	# Initialize the interface. This should trigger either _on_webxr_session_started
	# or _on_webxr_session_failed
	if not xr_interface.initialize():
		OS.alert("Failed to initialize WebXR")


# Set the XR frame rate to the configured value
func _set_xr_frame_rate() -> void:
	# Get the reported refresh rate
	xr_frame_rate = xr_interface.get_display_refresh_rate()
	if xr_frame_rate > 0:
		print("StartXR: Refresh rate reported as ", str(xr_frame_rate))
	else:
		print("StartXR: No refresh rate given by XR runtime")

	# Pick a desired refresh rate
	var desired_rate := target_refresh_rate if target_refresh_rate > 0 else xr_frame_rate
	var available_rates : Array = xr_interface.get_available_display_refresh_rates()
	if available_rates.size() == 0:
		print("StartXR: Target does not support refresh rate extension")
	elif available_rates.size() == 1:
		print("StartXR: Target supports only one refresh rate")
	elif desired_rate > 0:
		print("StartXR: Available refresh rates are ", str(available_rates))
		var rate = _find_closest(available_rates, desired_rate)
		if rate > 0:
			print("StartXR: Setting refresh rate to ", str(rate))
			xr_interface.set_display_refresh_rate(rate)
			xr_frame_rate = rate

	# Pick a physics rate
	var active_rate := xr_frame_rate if xr_frame_rate > 0 else 144.0
	var physics_rate := int(round(active_rate * physics_rate_multiplier))
	print("StartXR: Setting physics rate to ", physics_rate)
	Engine.physics_ticks_per_second = physics_rate


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
