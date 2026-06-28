extends Node3D

## Emitted when the shader cache has finished loading
signal cooldown_finished

## Frames needed to load the shader cache
var countdown: int = 2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	countdown = countdown - 1
	if countdown == 0:
		visible = false
		set_process(false)
		cooldown_finished.emit()
