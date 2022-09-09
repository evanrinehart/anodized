class_name MappedPlanet
extends MeshInstance

var material

var size = 0.5e6

var distance_mag setget set_distance_mag
var light1_direction setget set_light1_direction
var light1_color setget set_light1_color
var light2_direction setget set_light2_direction
var light2_color setget set_light2_color
var eclipse_angle setget set_eclipse_angle
var eclipse_matrix setget set_eclipse_matrix
var eclipse_hardness setget set_eclipse_hardness
var paint_color setget set_paint_color
var reflectance setget set_reflectance
var temperature setget set_temperature

#func set_parameter(val):
#	material.set_shader_param("parameter", val)

var current_grow = 1.0
func set_distance_mag(val):
	var grow = size / pow(10, val)
	scale = grow * Vector3.ONE
	material.set_shader_param("distance_mag", val)
	if name=="mars" and grow != current_grow:
		current_grow = grow
		print("size change mag=", val, " size=", size, " grow=", grow)

func set_light1_direction(dir):
	material.set_shader_param("light1_direction", dir)

func set_light1_color(c):
	material.set_shader_param("light1_color", c)

func set_light2_direction(dir):
	material.set_shader_param("light2_direction", dir)

func set_light2_color(c):
	material.set_shader_param("light2_color", c)

func set_eclipse_angle(val):
	material.set_shader_param("eclipse_angle", val)

func set_eclipse_matrix(val):
	material.set_shader_param("eclipse_matrix", val)

func set_eclipse_hardness(val):
	material.set_shader_param("eclipse_hardness", val)

func set_paint_color(val):
	material.set_shader_param("paint_color", val)

func set_reflectance(val):
	material.set_shader_param("reflectance", val)

func set_temperature(val):
	material.set_shader_param("temperature", val)
