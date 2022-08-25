extends Node

var avatar

var controls = {
	KEY_W: 0.0,
	KEY_S: 0.0,
	KEY_A: 0.0,
	KEY_D: 0.0
}

var roll_mode = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	avatar = get_parent()

func _unhandled_input(event):
	#if get_tree().network_peer and not is_network_master(): return
	
	if event is InputEventKey:
		if event.pressed and not event.is_echo():
			if event.scancode == KEY_W:   set_ctrl(event.scancode, 1.0)
			elif event.scancode == KEY_S: set_ctrl(event.scancode, 1.0)
			elif event.scancode == KEY_A: set_ctrl(event.scancode, 1.0)
			elif event.scancode == KEY_D: set_ctrl(event.scancode, 1.0)
			elif event.scancode == KEY_R: roll_mode = true
			elif event.scancode == KEY_SHIFT: avatar.enable_sprint(true)
			elif event.scancode == KEY_SPACE: avatar.execute_jump()
			elif event.scancode == KEY_H: avatar.press_H()
			elif event.scancode == KEY_ESCAPE:
				get_tree().quit()
		elif not event.is_echo():
			if event.scancode == KEY_W:   set_ctrl(event.scancode, 0.0)
			elif event.scancode == KEY_S: set_ctrl(event.scancode, 0.0)
			elif event.scancode == KEY_A: set_ctrl(event.scancode, 0.0)
			elif event.scancode == KEY_D: set_ctrl(event.scancode, 0.0)
			elif event.scancode == KEY_R: roll_mode = false
			elif event.scancode == KEY_SHIFT: avatar.enable_sprint(false)
	elif event is InputEventMouseMotion:
		if roll_mode:
			avatar.mouse_roll(event.relative[0])
		else:
			if event.relative[1] != 0.0: avatar.mouse_verti(event.relative[1])
			if event.relative[0] != 0.0: avatar.mouse_horiz(event.relative[0])

func set_ctrl(ctrl, value):
	controls[ctrl] = value
	avatar.updated_control(sum_controls())

func sum_controls():
	var w = controls[KEY_W]
	var a = controls[KEY_A]
	var s = controls[KEY_S]
	var d = controls[KEY_D]
	return Vector2(w-s, d-a)
