class_name Zector3
extends Reference

var i : int
var j : int
var k : int

func _init(a=0,b=0,c=0):
	assert(a is int)
	assert(b is int)
	assert(c is int)
	i = a
	j = b
	k = c

func plus(arg):
	assert(arg is get_script())
	return get_script().new(i+arg.i, j+arg.j, k+arg.k)

func minus(arg):
	return get_script().new(i-arg.i, j-arg.j, k-arg.k)

func negate():
	return get_script().new(-i, -j, -k)

func scale(n):
	assert(n is int)
	return get_script().new(n*i, n*j, n*k)

func dot(arg):
	return i*arg.i + j*arg.j + k*arg.k

func length_squared():
	return i*i + j*j + k*k

func is_zero():
	return i==0 && j==0 && k==0

func is_nonzero():
	return not is_zero()

func equals(arg):
	return i==arg.i && j==arg.j && k==arg.k

func differs_from(arg):
	return not equals(arg)

func cross(arg):
	var iout = j*arg.k - k*arg.j
	var jout = i*arg.k - k*arg.i
	var kout = i*arg.j - j*arg.i
	return get_script().new(iout, jout, kout)

func to_wector3():
	return Wector3.new(float(i),float(j),float(k))

func _to_string():
	return "<i=%d j=%d k=%d>" % [i,j,k]
