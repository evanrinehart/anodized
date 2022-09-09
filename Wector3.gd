class_name Wector3
extends Reference

var x : float
var y : float
var z : float

func _init(a=0.0,b=0.0,c=0.0):
	a = float(a)
	b = float(b)
	c = float(c)
	assert(a is float)
	assert(b is float)
	assert(c is float)
	x = a
	y = b
	z = c

static func from_vector(v):
	var klass = load("Wector3.gd")
	return klass.new(v.x, v.y, v.z)

static func from_z(z):
	var klass = load("Wector3.gd")
	return klass.new(0.0, 0.0, z)

func to_vector():
	return Vector3(x,y,z)

func plus(arg):
	return get_script().new(x+arg.x, y+arg.y, z+arg.z)

func minus(arg):
	return get_script().new(x-arg.x, y-arg.y, z-arg.z)

func negate():
	return get_script().new(-x, -y, -z)

func scale(s):
	return get_script().new(s*x, s*y, s*z)

func dot(arg):
	return x*arg.x + y*arg.y + z*arg.z

func length_squared():
	return x*x + y*y + z*z

func length():
	return sqrt(length_squared())

func normalized():
	var norm = length()
	return get_script().new(x / norm, y / norm, z / norm)

func is_zero():
	return x==0.0 && y==0.0 && z==0.0

func is_nonzero():
	return not is_zero()

func is_tiny():
	return length_squared() < 1e-18

func cross(arg):
	var xout = y*arg.z - z*arg.y
	var yout = x*arg.z - z*arg.x
	var zout = x*arg.y - y*arg.x
	return get_script().new(xout, yout, zout)

func overflow(limit, out):
	var ox = 0
	var oy = 0
	var oz = 0
	var llimit = 2*limit
	if   x >= limit:  ox += int((x + limit) / llimit)
	elif x <= -limit: ox -= int((x - limit) / llimit)
	if   y >= limit:  oy += int((y + limit) / llimit)
	elif y <= -limit: oy -= int((y - limit) / llimit)
	if   z >= limit:  oz += int((z + limit) / llimit)
	elif z <= -limit: oz -= int((z - limit) / llimit)
	out.i = ox
	out.j = oy
	out.k = oz

func _to_string():
	return "<x=%f y=%f z=%f>" % [x,y,z]


func decode_float(x):
	if is_inf(x) or is_nan(x):
		return null
	elif x < 0:
		var me = decodePositiveFloat(-x)
		return [-1, me[0], me[1]]
	elif x > 0:
		var me = decodePositiveFloat(x)
		return [1, me[0], me[1]]
	else:
		return [0, 0, 0]

func decodePositiveFloat(x):
	if x > 1.0:
		var e = -52
		while x >= 2.0:
			e += 1
			x /= 2.0
		var m = x * pow(2,52)
		return [m,e]
	elif x < 1.0:
		var e = -52
		while x < 1.0:
			e -= 1
			x *= 2.0
		var m = x * pow(2,52)
		return [m,e]
	else:
		return [pow(2,52), -52]
