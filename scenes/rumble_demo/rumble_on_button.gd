@icon("res://addons/godot-xr-tools/editor/icons/rumble.svg")
extends Node

## XR Tools Rumble Example: Rumble On Button Press


## Rumble event for pushing A or X
@export var ax_button_event : XRToolsRumbleEvent

## Rumble event for pushing B or Y
@export var by_button_event : XRToolsRumbleEvent


@onready var _controller : XRController3D = XRHelpers.get_xr_controller(self)


func _ready():
	_controller.button_pressed.connect(_on_button_pressed)


func _on_button_pressed(button_name: String) -> void:
	match button_name:
		"ax_button":
			XRToolsRumbleManager.add(_controller.name + "ax", ax_button_event, [_controller])
		"by_button":
			XRToolsRumbleManager.add(_controller.name + "by", by_button_event, [_controller])

