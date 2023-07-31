extends VBoxContainer

signal player_height_changed(new_height)


func _on_user_settings_ui_player_height_changed(new_height):
	emit_signal("player_height_changed", new_height)
