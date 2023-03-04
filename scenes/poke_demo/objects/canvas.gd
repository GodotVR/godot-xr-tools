extends Node2D

var draw_color : Color = Color(1.0, 1.0, 1.0, 1.0)
var active_brush : int = 0

func _clear():
	# make sure we don't draw anything first frame
	for i in $ViewportContainer/Viewport/Brushes.get_child_count():
		$ViewportContainer/Viewport/Brushes.get_child(i).visible = false

	# Make sure our viewport only updates once
	$ViewportContainer/Viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	$ViewportContainer/Viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

# Called when the node enters the scene tree for the first time.
func _ready():
	_clear()

func _update_active_brush():
	for i in $ViewportContainer/Viewport/Brushes.get_child_count():
		$ViewportContainer/Viewport/Brushes.get_child(i).visible = i == active_brush

func _on_ViewportContainer_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			_update_active_brush()
			$ViewportContainer/Viewport/Brushes.position = event.position
			$ViewportContainer/Viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	elif event is InputEventMouseMotion:
		# We're currently only getting these from our poke if we're touching,
		# but once viewport supports pressure we should implement this...
		_update_active_brush()
		$ViewportContainer/Viewport/Brushes.position = event.position
		$ViewportContainer/Viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _set_draw_color(p_color : Color) -> void:
	draw_color = p_color
	$ViewportContainer/Viewport/Brushes/Brush1.color = draw_color


func _on_WhiteButton_pressed():
	_set_draw_color(Color(1.0, 1.0, 1.0, 1.0))


func _on_BlackButton_pressed():
	_set_draw_color(Color(0.0, 0.0, 0.0, 1.0))


func _on_ClearButton_pressed():
	_clear()
