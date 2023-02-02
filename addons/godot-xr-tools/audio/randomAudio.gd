extends Spatial

func play():
	get_child(randi() % get_child_count()).play()
