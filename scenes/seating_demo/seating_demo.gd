@tool
extends DemoSceneBase

func _seat_button_released(button) -> void:
	get_node("Seat").seat()

func _unseat_button_released(button) -> void:
	get_node("Seat").unseat()




func _seat2_button_released(button) -> void:
	get_node("Seat2").seat()


func _unseat2_button_released(button) -> void:
	get_node("Seat2").unseat()


func _seat2_animate_button_released(button) -> void:
	get_node("Seat2/AnimationPlayer").play("move")
