extends Area3D

func _on_body_entered(body):
	if body is XRToolsPlayerBody:
		if !body.get_parent().has_node("MovementFlight"):
			printerr("Flight Area tried to find MovementFlight, but it could not...")
			return
		body.get_parent().get_node("MovementFlight").set_flying(true)


func _on_body_exited(body):
	if body is XRToolsPlayerBody:
		if !body.get_parent().has_node("MovementFlight"):
			printerr("Flight Area tried to find MovementFlight, but it could not...")
			return
		body.get_parent().get_node("MovementFlight").set_flying(false)
