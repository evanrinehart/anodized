class_name Point
extends Reference

# this is a representation of a point in space. The same point can be
# represented different ways. E.g.
#
# p = moon + 5
# p = sun + (moon - sun) + 5
# p = galaxy + (sun - galaxy) + (moon - sun) + 5

# the first term is a known point, aka landmarks
# other terms are displacements, which can be numeric values (MagVec)
# or the known landmark diffs (MagVec).
# i.e. it is known that
# moon = sun + (moon - sun)

# taking any points and producing a MagVec diff with a meaningful value means
# carefully doing a high precision calculation.

# but first we define the point and equip it with debug info

# things we need:
# 1. a way to move very slowly through coordinate system

# a point in space can be constructed by specifying a base point
# adding displacements. displacements may be changing in time, like (venus - sun)
# displacements may be standard (Wector valued) or extended (Zector valued). One
# extended displacement is worth 1000 microparsec (numeric value 1e15)
# standard coordinates range from 0 (center of extended grid cell) to 500e12
# where a transition to another cell would occur. transitions have hysteresis
# to avoid thrashing.

# examples
# mercury + <x=0 y=0 z=1.234npc> = sun + (mercury - sun) + <x=0 y=0 z=1.234npc>
# = sun + <x=0 y=0 z=2.501234upc>
# sun + Ex[i=1 j=0 k=0] + <x=0 y=0 z=0> # suns position 1000upc over

var base : String
var standard_shift : Wector3
var extended_shift : Zector3

func _init(a, b=null, c=null):
	assert(a is String)
	assert(b == null || b is Wector3)
	assert(c == null || c is Zector3)
	base = a
	standard_shift = b if b else Wector3.new(0,0,0)
	extended_shift = c if c else Zector3.new(0,0,0)

func _to_string():
	return base + " + " + str(SectorDiff.new(extended_shift, standard_shift))

static func wector3_to_skyspace(w):
	var lx = linear2db(abs(w.x)) / 20
	var ly = linear2db(abs(w.y)) / 20
	var lz = linear2db(abs(w.z)) / 20
	var e1 = int(floor(lx)) / 3 * 3
	var e2 = int(floor(ly)) / 3 * 3
	var e3 = int(floor(lz)) / 3 * 3
	var mag = max(e1, max(e2, e3))
	var pot = pow(10, mag)
	return {
		"vec": Vector3(w.x / pot, w.y / pot, w.z / pot),
		"mag": mag
	}

func shift(dx : Wector3):
	assert(dx is Wector3)
	standard_shift = standard_shift.plus(dx)

# point + displacement => point
func plus(dx : Wector3):
	var p = get_script().new()
	p.base = base
	p.standard_shift = standard_shift.plus(dx)
	p.extended_shift = extended_shift
	return p

# mercury + 3 => sun + (mercury - sun) + 3 => sun + 2503
func lift(codex):
	assert(false, "not yet implemented")


# diff two points if they share base and have same extended shift
func local_diff(p):
	assert(p.base == base)
	assert(p.extended_shift.equals(extended_shift))
	return standard_shift.minus(p.standard_shift)


"""
# point - point = displacement
func diff(arg, codex):
	var p1 = self
	var p0 = arg
	
	var common_landmark = get_common_landmark(p1, p0, codex)
	p1 = change_base_point(p1, common_landmark)
	p0 = change_base_point(p0, common_landmark)
	
	var table = {}
	
	for term in p1.displacements:
		var d = codex.get_displacement(term) if term is String else term
		if not table.has(d.mag): table[d.mag] = Vector3()
		table[d.mag] += d.vec
		
	for term in p0.displacements:
		var d = codex.get_displacement(term) if term is String else term
		if not table.has(d.mag): table[d.mag] = Vector3()
		table[d.mag] -= d.vec
	
	var m = -100
	for k in table:
		if table[k].length_squared() > 0.0 and k > m:
			m = k

	var v = Vector3()
	for e in table:
		var shrink = pow(10, m - e)
		v += table[e] / shrink
	
	if v.length_squared() < 1e-12:
		return MagVec.new()
	else:
		return MagVec.new(v, m)
"""
