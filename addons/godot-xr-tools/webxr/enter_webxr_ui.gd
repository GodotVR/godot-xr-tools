extends CanvasLayer

var webxr_interface: WebXRInterface

func _ready() -> void:
	visible = false

	webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		webxr_interface.session_supported.connect(self._on_webxr_session_supported)
		webxr_interface.session_started.connect(self._on_webxr_session_started)
		webxr_interface.session_ended.connect(self._on_webxr_session_ended)
		webxr_interface.session_failed.connect(self._on_webxr_session_failed)

		webxr_interface.is_session_supported("immersive-vr")


func _on_webxr_session_supported(session_mode: String, supported: bool) -> void:
	if session_mode == "immersive-vr":
		if supported:
			visible = true
		else:
			OS.alert("Your web browser doesn't support VR. Sorry!")


func _on_webxr_session_started() -> void:
	visible = false
	get_viewport().use_xr = true


func _on_webxr_session_ended() -> void:
	visible = true
	get_viewport().use_xr = false


func _on_webxr_session_failed(message: String) -> void:
	OS.alert("Unable to enter VR: " + message)
	visible = true


func _on_enter_vr_button_pressed():
	webxr_interface.session_mode = 'immersive-vr'
	webxr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
	webxr_interface.required_features = 'local-floor'
	webxr_interface.optional_features = 'bounded-floor'

	if not webxr_interface.initialize():
		OS.alert("Failed to initialize WebXR")
