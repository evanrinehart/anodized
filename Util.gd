class_name Util
extends Object

static func astroformat(x):
	var ab = abs(x)
	var km = 30.0 * ab / 1e3
	if  ab >= 1e18: return "%.3fkpc"   % (x / 1e18)
	elif  ab >= 1e15: return "%.3fpc"   % (x / 1e15)
	elif  ab >= 1e12: return "%.3fmpc"   % (x / 1e12)
	elif  ab >= 1e9: return "%.3fupc"   % (x / 1e9)
	elif km > 10000.0: return "%.3fnpc"  % (x / 1e6)
	elif km > 1.0: return "%.3fkm" % (30.0 * x / 1e3)
	else: return "%.3fm" % (30.0 * x)

static func astroformat_ex(i):
	if i == 0: return "0"
	var ab = abs(i)
	var divisor
	var suffix
	var pad
	if ab >= 1000000000000:
		divisor = 1000000000000
		pad = 12
		suffix = "Gpc"
	elif ab >= 1000000000:
		divisor = 1000000000
		pad = 9
		suffix = "Mpc"
	elif ab >= 1000000:
		divisor = 1000000
		pad = 6
		suffix = "kpc"
	elif ab >= 1000:
		divisor = 1000
		pad = 3
		suffix = "pc"
	else:
		divisor = 1
		suffix = "mpc"
	
	var whole = ab / divisor
	var frac = ab % divisor
	var s = "-" if i < 0 else ""
	if divisor > 1:
		if frac > 0: return ("%s%d.%0"+str(pad)+"d%s") % [s, whole, frac, suffix]
		else: return "%s%d%s" % [s, whole, suffix]
	else:
		return "%d%s" % [i, suffix]
