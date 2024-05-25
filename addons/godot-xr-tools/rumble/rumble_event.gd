@icon("res://addons/godot-xr-tools/editor/icons/rumble.svg")
class_name XRToolsRumbleEvent
extends Resource

## XR Tools Rumble Event Resource

## Strength of the rumbling
@export_range(0, 1, 0.10) var magnitude: float = 0.5

## Whether the rumble can be active during a tree pause
@export var active_during_pause: bool = false

@export_category("Timing")

## Whether the rumble continues until cleared
@export var indefinite: bool = false

## Time to rumble (unless indefinite)
@export_range(10, 4000, 10) var duration_ms: int = 300
