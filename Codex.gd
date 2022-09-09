class_name Codex
extends Resource

var landmarks = {}
var displacements = {}

func add_root_landmark(name, size, soi=null):
	if soi == null: soi = size * 5
	
	landmarks[name] = {
		"name": name,
		"base": null,
		"size": size,
		"soi": soi,
		"depth": 0
	}

func add_landmark(name, point, size, soi=null):
	assert(point is Point)
	assert(landmarks.has(point.base), "landmark base not found")
	if soi == null: soi = size * 5

	var depth = get_depth(point.base)

	landmarks[name] = {
		"name": name,
		"base": point.base,
		"size": size,
		"soi": soi,
		"depth": depth
	}

	displacements[name + " - " + point.base] = {
		"std": point.standard_shift,
		"ext": point.extended_shift
	}

func landmark_line(l):
	var mark = landmarks[l]
	var arr = []
	arr.push_back(mark.name)
	if mark.base:
		var disp = displacements[mark.name + " - " + mark.base]
		var p = load("Point.gd").new(mark.base, disp.std, disp.ext)
		arr.push_back("(" + str(mark.depth) + ") = " + str(p))
	return "".join(arr)

func debug():
	for l in landmarks:
		print(landmark_line(l))


func traverse_up(l, n):
	for i in range(0,n):
		l = landmarks[l].base
	return l

func get_depth(name):
	var d = 0
	while name:
		assert(landmarks.has(name))
		name = landmarks[name].base
		d += 1
	return d

func get_common_landmark(l1, l2):
	#print("get common ", l1, " ", l2)
	var base1 = landmarks[l1].base
	var base2 = landmarks[l2].base
	if l1 == l2: return l1
	if l1 == base2: return l1
	if base1 == l2: return l2
	
	var d1 = landmarks[l1].depth
	var d2 = landmarks[l2].depth
	if d1 > d2:
		l1 = traverse_up(l1, d1 - d2)
	elif d1 < d2:
		l2 = traverse_up(l2, d2 - d1)
	
	#print("d1=", d1, " d2=", d2)

	var guardrail = 0
	while l1 != l2:
		guardrail += 1
		if guardrail > 100:
			assert(false, "common_landmark guardrail")
		l1 = landmarks[l1].base
		l2 = landmarks[l2].base
	
	return l1

# earth + 5 => sun + ((earth - sun) + 5)
func lift(p):
	var old_base = p.base
	var new_base = landmarks[p.base].base
	var term = displacements[old_base + " - " + new_base].std
	return Point.new(new_base, term.plus(p.standard_shift))

# p must be under new_base
func rebase(p, new_base):
	while p.base != new_base:
		p = lift(p)
	return p
	
# assuming we are in the same sector!
func diff(p1, p2):
	if p1.base == p2.base: return p1.local_diff(p2)
	#print("p1=", p1, " base1=", p1.base, " p2=", p2, " base2=", p2.base)
	var common = get_common_landmark(p1.base, p2.base)
	p1 = rebase(p1, common)
	p2 = rebase(p2, common)
	return p1.local_diff(p2)

func big_lift(p):
	var old_base = p.base
	var new_base = landmarks[p.base].base
	#print("old base = ", old_base)
	#print("new base = ", new_base)
	var disp = displacements[old_base + " - " + new_base]
	#print("disp = ", disp)
	var conversion = SectorDiff.new(disp.ext, disp.std)
	#print("conversion = ", conversion)
	var old_shift = SectorDiff.new(p.extended_shift, p.standard_shift)
	#print("old shift = ", old_shift)
	var new_shift = conversion.plus(old_shift)
	#print("new shift = ", new_shift)
	return Point.new(new_base, new_shift.std, new_shift.ext)

# p must be under new_base
func big_rebase(p, new_base):
	#print("big rebase ", p, " to ", new_base)
	while p.base != new_base:
		p = big_lift(p)
	return p

# 
func big_diff(p1, p2):
	if p1.base == p2.base: return p1.local_diff(p2)
	var common = get_common_landmark(p1.base, p2.base)
	p1 = big_rebase(p1, common)
	p2 = big_rebase(p2, common)
	#print("big diff p1 = ", p1)
	#print("big diff p2 = ", p2)
	var sd1 = SectorDiff.new(p1.extended_shift, p1.standard_shift)
	var sd2 = SectorDiff.new(p2.extended_shift, p2.standard_shift)
	var bd = sd1.minus(sd2)
	#print("p1 - p2 = ", bd)
	return sd1.minus(sd2)
