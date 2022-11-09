extends Node2D


func _on_ClearButton_pressed():
	$Container/Line1/TextEdit.text = ""
	$Container/Line2/TextEdit.text = ""
	$Container/Line3/TextEdit.text = ""
