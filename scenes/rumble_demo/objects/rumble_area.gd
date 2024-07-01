@tool
@icon("res://addons/godot-xr-tools/editor/icons/rumble.svg")
extends Area3D

## Area to Rumble when standing within

## Rumble details
@export var event: XRToolsRumbleEvent

## Color of the ring
@export var ring_color: Color = Color.GREEN_YELLOW

# Called when the node enters the scene tree for the first time.
func _ready():
	var material := StandardMaterial3D.new()
	material.albedo_color = ring_color

	$MeshInstance3D.set_surface_override_material(0, material)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if XRTools.is_xr_class(body, "XRToolsPlayerBody"):
		XRToolsRumbleManager.add(self, event)


func _on_body_exited(body):
	if XRTools.is_xr_class(body, "XRToolsPlayerBody"):
		XRToolsRumbleManager.clear(self)
