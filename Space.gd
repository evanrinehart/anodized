extends Spatial

var space_material

var venus_texture
var mars_texture
var earth_texture
var mercury_texture

var codex
var holodeck
var camera
var observer

func _ready():
	
	camera = get_node("ViewportContainer/FGViewport/Observer/Camera")
	
	var Point = load("Point.gd")
	var zero = Wector3.new(0.0, 0.0, 0.0)
	codex = Codex.new()
	codex.add_root_landmark("sun", 22e6, 5000e9)
	codex.add_landmark("earth",   Point.new("sun", Wector3.new(0, 0, -5e9)), 1e6)
	codex.add_landmark("venus",   Point.new("sun", Wector3.new(0, 0, -3.5e9)), 1e6)
	codex.add_landmark("mercury", Point.new("sun", Wector3.new(0, 0, -2e9)), 0.25e6)
	codex.add_landmark("mars",    Point.new("sun", Wector3.new(0, 0, -7.5e9)), 0.333e6)
	codex.add_landmark("platform",Point.new("mars", Wector3.new(0,0,0.4e6)), 30)
	codex.debug()
	
	var vp1 = get_node("ViewportContainer/BGViewport")
	var vp2 = get_node("ViewportContainer/FGViewport")
	var winsize = get_viewport().get_visible_rect().size
	#print("winsize = ", winsize)
	vp1.size = winsize
	vp2.size = winsize
	
	
	observer = get_node("ViewportContainer/FGViewport/Observer")
	holodeck = get_node("ViewportContainer/BGViewport/Holodeck")
	observer.hud = get_node("HUD")
	
	holodeck.codex = codex
	observer.point = Point.new("platform", Wector3.new(1,1,1))
	
	earth_texture = preload("res://earth.jpg")
	mercury_texture = preload("res://mercury.jpg")
	venus_texture = preload("res://venus.jpg")
	mars_texture = preload("res://mars.jpg")
	
	var sun = holodeck.spawn_object("sun")
	var d = codex.diff(observer.point, Point.new("sun"))
	var sk = Point.wector3_to_skyspace(d)
	print("sun at ", sk)
	sun.transform.origin = -sk.vec
	sun.distance_mag = sk.mag
	sun.temperature = 6000
	sun.reflectance = 0.0
	
	var earth = holodeck.spawn_object("earth", earth_texture)
	d = codex.diff(observer.point, Point.new("earth"))
	sk = Point.wector3_to_skyspace(d)
	print("earth at ", sk)
	earth.transform.origin = -sk.vec
	earth.distance_mag = sk.mag
	earth.transform.basis = Basis(Vector3(0,1,0),PI)
	earth.light1_direction = earth.transform.origin - sun.transform.origin
	
	var mercury = holodeck.spawn_object("mercury", mercury_texture)
	d = codex.diff(observer.point, Point.new("mercury"))
	sk = Point.wector3_to_skyspace(d)
	print("mercury at ", sk)
	mercury.transform.origin = -sk.vec
	mercury.distance_mag = sk.mag
	mercury.light1_direction = mercury.transform.origin - sun.transform.origin
	
	var venus = holodeck.spawn_object("venus", venus_texture)
	d = codex.diff(observer.point, Point.new("venus"))
	sk = Point.wector3_to_skyspace(d)
	print("venus at ", sk)
	venus.transform.origin = -sk.vec
	venus.distance_mag = sk.mag
	venus.light1_direction = venus.transform.origin - sun.transform.origin
	
	var mars = holodeck.spawn_object("mars", mars_texture)
	d = codex.diff(observer.point, Point.new("mars"))
	sk = Point.wector3_to_skyspace(d)
	print("mars at ", sk)
	mars.transform.origin = -sk.vec
	mars.distance_mag = sk.mag
	mars.light1_direction = mars.transform.origin - sun.transform.origin
	
	observer.connect("camera_changed", self, "on_camera_changed")
	
	set_camera_fov(70)
	pass

func on_camera_changed(basis):
	holodeck.set_camera_attitude(basis)

func set_camera_fov(angle):
	camera.fov = angle
	holodeck.set_camera_fov(angle)

var theta = 0.0
func _physics_process(delta):
	for node in holodeck.get_objects():
		var d = codex.diff(observer.point, Point.new(node.name))
		var sk = Point.wector3_to_skyspace(d)
		node.transform.origin = -sk.vec
		node.distance_mag = sk.mag
		
		
	#var earth = holodeck.get_object("earth")
	#theta += delta/5.0
	#var d = Vector3(1,0,0).rotated(Vector3(0,1,0), theta)
	#earth.light1_direction = d
	pass

"""
func spawn_cosmic_object(config):
	var obj = CosmicSphere.new()
	obj.name = config.name
	obj.mesh = SphereMesh.new()
	var size_correct = pow(10, config.position_mag - config.size_mag)
	obj.mesh.radius = config.size / size_correct
	obj.mesh.height = config.size * 2 / size_correct
	obj.extra_cull_margin = 1000
	var material = space_material.duplicate()
	material.set_shader_param("order_of_magnitude", config.position_mag)
	material.set_shader_param("shrink_factor", 1.0)
	material.set_shader_param("reflectance", config.reflectance)
	material.set_shader_param("paint_color", config.paint_color)
	material.set_shader_param("light1_direction", config.light1_direction)
	material.set_shader_param("light1_color", config.light1_color)
	material.set_shader_param("light2_direction", config.light2_direction)
	material.set_shader_param("light2_color", config.light2_color)
	material.set_shader_param("temperature", config.temperature)
	material.set_shader_param("texture1", config.texture1)
	obj.set_surface_material(0, material)
	obj.transform.origin = config.position
	obj.transform.basis  = config.attitude
	obj.magnitude = config.position_mag
	obj.size = config.size
	#obj.velocity = config.velocity
	add_child(obj)
	return obj
"""
"""
func load_cosmic_objects():
	var objects = {}
	
	var dir = Directory.new()
	dir.open("res://cosmic_objects")
	var err = dir.list_dir_begin(true)
	if err == OK:
		while true:
			var filename = dir.get_next()
			if filename != "":
				var res = load("res://cosmic_objects/" + filename)
				print("res=", res)
				objects[res.name] = res
				#res.size = MagNum.new(10, 6)
				#ResourceSaver.save("cosmic_objects/" + filename, res)
			else:
				break
	else:
		print("open dir error = ", err)
	
	return objects
"""

var zoom = 70
func _unhandled_input(event):
	if Input.is_action_pressed("zoom_in"):
		zoom -= 5
		if zoom < 5: zoom = 5
		set_camera_fov(zoom)
	if Input.is_action_pressed("zoom_out"):
		zoom += 5
		if zoom > 80: zoom = 80
		set_camera_fov(zoom)
		
