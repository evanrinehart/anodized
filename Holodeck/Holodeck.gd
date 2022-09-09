extends Spatial

var planet
var gallery
var camera

var sky_warp_material

var codex

func _ready():
	sky_warp_material = preload("res://sky_warp.material")
	gallery = get_node("Gallery")
	planet = get_node("Shelf/MappedPlanet")
	camera = get_node("Camera")
	
	
	var mat = planet.get_surface_material(0)
	var shadow1 = mat.get_shader_param("shadow_matrix")
	var shadow2 = Transform.IDENTITY.rotated(Vector3(1,0,0),0.0).translated(Vector3(-0.14,0,4))
	mat.set_shader_param("shadow_matrix", shadow2)

var theta = 0.0
func _physics_process(delta):
	theta += delta/4.0
	var planet = get_node("Shelf/MappedPlanet")
	planet.transform.basis = planet.transform.basis.rotated(Vector3(0,1,0), delta/8.0)
	var mat = planet.get_surface_material(0)
	var shadow = Transform.IDENTITY.rotated(Vector3(1,0,0),0.0).translated(Vector3(0.25*cos(theta),0.25*sin(theta),8))
	mat.set_shader_param("shadow_matrix", shadow)

func set_camera_attitude(b):
	camera.transform.basis = b

func set_camera_fov(angle):
	camera.fov = angle

func move_object(name, position, distance_mag, basis, size_factor=1.0):
	var node = gallery.get_node(name)
	var material = node.get_surface_material(0)
	material.set_shader_param("distance_mag", distance_mag)
	node.transform.origin = position
	node.transform.basis = basis
	node.scale = Vector3.ONE * size_factor

func set_lights(name, direction):
	var node = gallery.get_node(name)
	var material = node.get_surface_material(0)
	material.set_shader_param("light1_direction", direction)

"""
func add_object(name, texture, position, distance_mag, basis, size_factor=1.0):
	var node = MeshInstance.new()
	var sphere = SphereMesh.new()
	var mat = sky_warp_material.duplicate()
	sphere.radius = 0.5
	sphere.height = 1.0
	mat.set_shader_param("texture1", texture)
	mat.set_shader_param("distance_mag", distance_mag)
	node.name = name
	node.mesh = sphere
	node.transform.origin = position
	node.transform.basis = basis
	node.scale = Vector3.ONE * size_factor
	node.set_surface_material(0, mat)
	gallery.add_child(node)
"""

func get_objects():
	return gallery.get_children()

func get_object(name):
	return gallery.get_node(name)

func delete_object(name):
	gallery.get_node(name).queue_free()

func spawn_object(name, texture=null):
	var node = MappedPlanet.new()
	var sphere = SphereMesh.new()
	var mat = sky_warp_material.duplicate()
	sphere.radius = 0.5
	sphere.height = 1.0
	mat.set_shader_param("texture1", texture)
	node.name = name
	node.mesh = sphere
	node.set_surface_material(0, mat)
	node.material = mat
	node.extra_cull_margin = 4000.0
	node.size = codex.landmarks[name].size
	gallery.add_child(node)
	return node
