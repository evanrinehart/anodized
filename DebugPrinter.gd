extends Control

var line_count = 50
var labels = []
var current_line = 0

func _ready():
	for i in range(0,line_count):
		var label = Label.new()
		label.anchor_right = 0
		label.margin_right = 0
		label.margin_top = 14 * i
		label.add_color_override("font_color", Color(1,1,0,1))
		label.add_color_override("font_color_shadow", Color(0,0,0,1))
		label.add_constant_override("shadow_offset_x", 1)
		label.add_constant_override("shadow_offset_y", 1)
		labels.push_back(label)
		add_child(label)

func put_line(label, value):
	if frozen: return
	var string = "%s: %s" % [label, str(value)]
	if current_line == line_count:
		form_feed()
		labels[line_count-1].text = string
	else:
		labels[current_line].text = string
		current_line += 1

func form_feed():
	for i in range(0, line_count - 1):
		labels[i].text = labels[i+1].text
	#labels[line_count-1].text = ""

func clear():
	for i in range(0, line_count):
		labels[i].text = ""

var frozen = false
func freeze():
	frozen = !frozen
	

"""
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
		else:
			put_line("%d a line of text" % get_tree().get_frame())
"""
