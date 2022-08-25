extends Control

var label
var display

func _ready():
	label = get_node("Label")
	display = get_node("Display")

func set_label(txt):
	label.text = txt

func set_display(txt):
	display.text = str(txt)

func present(lab, value):
	label.text = lab
	display.text = str(value)
