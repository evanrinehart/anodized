class_name SectorDiff
extends Reference

var ext
var std

func _init(a=null, b=null):
	ext = Zector3.new() if a==null else a
	std = Wector3.new() if b==null else b
	assert(a is Zector3)
	assert(b is Wector3)

func negate():
	var ext2 = ext.negate()
	var std2 = std.negate()
	return get_script().new(ext2, std2)

func plus(arg):
	var ext2 = ext.plus(arg.ext)
	var std2 = std.plus(arg.std)
	var ext2over = Zector3.new()
	std2.overflow(500e9, ext2over)
	if ext2over.is_nonzero():
		ext2 = ext2.plus(ext2over)
		std2.x -= ext2over.i * 1e12
		std2.y -= ext2over.j * 1e12
		std2.z -= ext2over.k * 1e12
	return get_script().new(ext2, std2)

func minus(arg):
	var ext2 = ext.minus(arg.ext)
	var std2 = std.minus(arg.std)
	var ext2over = Zector3.new()
	std2.overflow(500e9, ext2over)
	if ext2over.is_nonzero():
		ext2 = ext2.plus(ext2over)
		std2.x -= ext2over.i * 1e12
		std2.y -= ext2over.j * 1e12
		std2.z -= ext2over.k * 1e12
	return get_script().new(ext2, std2)

func length_squared():
	var a = ext.i * 1e12
	var b = std.x
	var xx = a*a + 2*a*b + b*b
	a = ext.j * 1e12
	b = std.y
	var yy = a*a + 2*a*b + b*b
	a = ext.k * 1e12
	b = std.z
	var zz = a*a + 2*a*b + b*b
	return xx + yy + zz

func length():
	return sqrt(length_squared())

func is_small():
	return ext.is_zero()

func _to_string():
	if ext.is_zero() and std.is_zero(): return "(0,0,0)"
	var arr = PoolStringArray()
	if ext.is_nonzero():
		var i = Util.astroformat_ex(ext.i)
		var j = Util.astroformat_ex(ext.j)
		var k = Util.astroformat_ex(ext.k)
		arr.push_back("[x=%s y=%s z=%s]" % [i,j,k])
	if std.is_nonzero():
		var x = Util.astroformat(std.x)
		var y = Util.astroformat(std.y)
		var z = Util.astroformat(std.z)
		arr.push_back("{x=%s y=%s z=%s}" % [x,y,z])
	return " + ".join(arr)
