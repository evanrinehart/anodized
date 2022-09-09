extends Spatial

signal camera_changed

var point
var velocity = Wector3.new(0.0,0.0,0.0)
var acceleration = Vector3()

var azimuth = 0.0
var inclination = 0.0
var dirty_cam = true

var codex
var within_list = {}

var hud = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass
	
func _physics_process(delta):
	#get_node("Camera").transform.basis = Basis.IDENTITY.rotated(Vector3(1,0,0), inclination).rotated(Vector3(0,1,0), azimuth)
	transform.basis = Basis.IDENTITY.rotated(Vector3(1,0,0), inclination).rotated(Vector3(0,1,0), azimuth)
	
	if dirty_cam:
		dirty_cam = false
		emit_signal("camera_changed", transform.basis)
	
	var thrust_dir = transform.basis.xform(acceleration)
	var thrust = Wector3.from_vector(thrust_dir).scale(0.33)
	#var thrust = Wector3.from_vector(thrust_dir).scale(1000)
	
	velocity = velocity.plus(thrust.scale(delta))
	
	point.standard_shift = point.standard_shift.plus(velocity.scale(delta))
	
	#var d = point.standard_shift.scale(30).to_vector()
	transform.origin = point.standard_shift.scale(30).to_vector()

	#if velocity.length_squared() > 0.0:
		#get_parent().relocate_observer(point)
	
	if hud: hud.present("position", point)
	#if hud: hud.present("gravity", gravity)

	

func _unhandled_input(event):
	if event is InputEventKey:
		if not event.is_echo():
			var press = event.pressed
			if event.scancode == KEY_W:   acceleration.z -= 1.0 if press else -1.0
			elif event.scancode == KEY_S: acceleration.z += 1.0 if press else -1.0
			elif event.scancode == KEY_A: acceleration.x -= 1.0 if press else -1.0
			elif event.scancode == KEY_D: acceleration.x += 1.0 if press else -1.0
			elif event.scancode == KEY_R: acceleration.y += 1.0 if press else -1.0
			elif event.scancode == KEY_F: acceleration.y -= 1.0 if press else -1.0
			elif event.scancode == KEY_ESCAPE:
				get_tree().quit()
	elif event is InputEventMouseMotion:
		if event.relative[1] != 0.0:
			inclination += -event.relative[1]/600.0
			dirty_cam = true
		if event.relative[0] != 0.0:
			azimuth += -event.relative[0]/600.0
			dirty_cam = true
