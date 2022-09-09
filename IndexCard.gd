extends Panel

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		print("index card got an mouse event")
	if event is InputEventKey:
		print("index card got a key event")
