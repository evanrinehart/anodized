class_name FPSCharTest
extends RigidBody

signal smacked_surface
signal detached_from_surface

var GRAVITY = Vector3(0,0,0)
var JUMP = 10
var WALK = 1
var RUN = 2
var collision_shape_z
var collision_shape_g
var mesh
var control = Vector2(0,0)
var smack = null
var smack_cooldown = false
var smack_cooldown2 = 0
var camera
var debug
var hud
var ground_mode = false
var accelerando = Accelerando.new()
var floormaster = Floormaster.new()
#var edge_tester = EdgeTester.new()
var camera_undisorientator = CameraUndisorientator.new()
var deferred_jump = null
var cached_velocity = Vector3(0,0,0)
var snap_flag = true
var tracked_surfaces = []
var feet_status = {}
var jetpack = 0.0
var jetpackUD = 0.0
var nearby_bodies = []
var area
var jump_mode = false
var bump_immunity = true
var bump_force = Vector3(0,0,0)
var landing_shape_timer = 0


var clue_rate = 10
var clue_timer = 0

func _ready():
	#debug = get_parent().get_node("CanvasLayer/DebugPrinter")
	#hud = get_parent().get_node("CanvasLayer/HUD")
	#hud.call_deferred("set_label", "clues")
	area = get_node("Area")
	collision_shape_z = get_node("CollisionShapeZ")
	collision_shape_g = get_node("CollisionShapeG")
	mesh = get_node("MeshInstance")
	camera = get_node("Camera")
	var area = get_node("Area")
	connect("smacked_surface", self, "on_smacked_surface")
	area.connect("body_entered", self, "on_proximity_enter")
	area.connect("body_exited", self, "on_proximity_exit")
	#my_shadow = get_parent().get_node("Player2")


var nbos = []
func on_proximity_enter(node):
	if(node == self): return
	nbos.push_back(node)

func on_proximity_exit(node):
	nbos.erase(node)

# postmortem: useless, weird normals
func get_contact_normal1(state : PhysicsDirectSpaceState):
	var query = PhysicsShapeQueryParameters.new()
	var shape = get_node("CollisionShape")
	query.shape_rid = PhysicsServer.body_get_shape(get_rid(), 0)
	query.transform = shape.global_transform
	var info = state.get_rest_info(query)
	return info.normal

# surprisingly the normals look good... most of the time
func get_contact_normals(state):
	var N = state.get_contact_count()
	var ns = []
	for i in range(0,N):
		ns.push_back(state.get_contact_local_normal(i))
	return ns

func get_contact_velocities(state):
	var N = state.get_contact_count()
	var ns = []
	for i in range(0,N):
		ns.push_back(state.get_contact_collider_velocity_at_position(i))
	return ns

# contact points are always returned relative to body origin ignoring rotation
func get_contact_points(state):
	var N = state.get_contact_count()
	var ps = []
	for i in range(0,N):
		var local_p = state.get_contact_local_position(i)
		var p = state.transform.origin + local_p
		ps.push_back(p)
	return ps

func ray_cast(origin, vector):
	var space = PhysicsServer.space_get_direct_state(get_world().space)
	var from = origin
	var to = origin + vector * 2
	if my_shadow:
		return space.intersect_ray(from, to, [get_rid(), my_shadow.get_rid()])
	else:
		return space.intersect_ray(from, to, [get_rid()])

# wow will this solve all the algorithms?
func feet_cast():
	var result = PhysicsTestMotionResult.new()
	var hit = PhysicsServer.body_test_motion(get_rid(), global_transform, -transform.basis.y, true, result)
	if hit:
		return {
			"collider": result.collider,
			"point": result.collision_point,
			"normal": result.collision_normal
		}
	else:
		return {}

func on_smacked_surface(info):
	
	var average_point = average3(info.points)
	var average_normal = average3(info.normals)
	var average_velocity = average3(info.velocities)
	
	print("average point", average_point)
	
	#debug.put_line("smack", [average_point, average_normal, average_velocity])
	#debug.put_line("AVERAGE POINT", average_point)
	
	var normal = average_normal
	
	var down = -transform.basis.y
	
	var impact_velocity = -average_velocity.project(normal)
	var tangential_velocity = average_velocity - impact_velocity
	
	#var result = down_probe(transform.origin, transform.basis, space)
	#if result 
	#debug.put_line("result", result)
	
	var a1 = GRAVITY.project(normal)
	#var a2 = average_velocity.project(normal)
	var a2 = Vector3.ZERO
	#if a2.length() < 0.5: a2 = Vector3.ZERO
	var compression = (a1 + a2).dot(normal)
	#print("GRAVITY", GRAVITY)
	#print("normal", average_normal)
	#debug.put_line("angle", rad2deg(abs((-GRAVITY).angle_to(average_normal))))
	if GRAVITY.length_squared() == 0.0:
		# 2nd law of motion
		# you can only leave freefall mode if gravity (exists) and points into the surface
		return
	if abs((-GRAVITY).angle_to(average_normal)) < PI/3: # you could supposedly stand here at the moment
		#accelerando.set_direction(impact_velocity.normalized())
		#accelerando.impulse(impact_velocity.length())
		if ray_cast(transform.origin, -transform.basis.y): # only land if feet touching something
			# which will cause problems if you wanted to land on a wall sideways
			freefall_to_ground_mode(average_point, average_normal)
		pass
		
	#print(get_tree().get_frame(), " SMACK ", info, " RB ", transform.origin)
	#debug.put_line("SMACK", str(info))




var ground_up
var ground_forward
var ground_right
var ground_normal
var ground_velocity = Vector3(0,0,0)
var ground_friction
var ground_camera_inclination = 0.0
#var ground_camera_azimuth = 0.0
#var ground_camera_dazimuth = 0.0
var ground_speed = 1.0
var ground_target_basis

func freefall_to_ground_mode(foot_point, surface_normal):
	# MAYBE RELEVANT at this point linear_velocity is pointing opposite
	# what you think it is
	#ground_velocity = linear_velocity # will quickly be deflected by move and slide
	
	mode = RigidBody.MODE_KINEMATIC
	
	ground_mode = true
	transform.origin = foot_point + surface_normal * 1.0 # height / 2
	print("foot_point", foot_point)
	print("surface_normal", surface_normal)
	#var original_forward = -transform.basis.z
	
	var old_forward = -camera.global_transform.basis.z
	
	#print("old up", transform.basis.y)
	var up = which_way_is_up(surface_normal)
	#print("new up", up)
	
	var old_basis = camera.global_transform.basis
	#debug.put_line("old_basis", old_basis)
	recompute_basis_due_to_change_in_up(up)
	ground_camera_inclination = synthetic_inclination(old_forward, global_transform.basis.y)
	var new_basis = transform.basis
	camera.transform.basis = new_basis.transposed() * old_basis
	var camera_target = Basis.IDENTITY.rotated(Vector3(1,0,0), ground_camera_inclination)
	camera_undisorientator.undisorientate(new_basis.transposed() * old_basis, camera_target)
	
	ground_up = transform.basis.y
	ground_forward = -transform.basis.z
	ground_right = transform.basis.x

	floormaster.velocity = ground_velocity
	floormaster.chdir(ground_forward, ground_right)
	floormaster.ctrl(control)
	
	#print("toggling collision shapes Z -> G")
	landing_shape_timer = 5


func ground_mode_to_freefall():
	
	mode = RigidBody.MODE_CHARACTER
	angular_velocity = angular_velocity
	
	ground_mode = false
	
	#print("toggling collision shapes G -> Z")
	collision_shape_g.set_deferred("disabled", true)
	collision_shape_z.set_deferred("disabled", false)
	#camera.transform.basis = Basis.IDENTITY
	# zero out the camera and orient the body toward that direction without the player noticing


var theta = 0
var room_spin = 0.0
var cc = 0
### GROUND MODE
func _physics_process(delta):
	
	#hud.present("origin", transform.origin)
	#hud.present("flag1", control_flag1)
	
	#cc += 1
	#if cc % 240 == 0:
		#clue()
	#print("angular velocity", angular_velocity)
	#angular_velocity = angular_velocity
	
	feet_status = feet_cast()
		
	
	#var info = ray_cast(transform.origin, -feet_status.normal)
	#hud.present("feetnormal", feet_status.normal if feet_status else {})
	
	#hud.present("feet", feet_status.normal if feet_status else "{}")
	#hud.present("forward", -camera.global_transform.basis.z)
	#hud.present("edge test", the_edge_test())
	
	#theta += delta/10.0 * room_spin
	#GRAVITY = Vector3(0,-10,0).rotated(Vector3(0,0,1), theta)
	
	#hud.present("origin", transform.origin)

	if ground_mode:
		if camera_undisorientator.param < 1.0:
			camera.transform.basis = camera_undisorientator.current_matrix()
			camera_undisorientator.step(delta)
		else:
			camera.transform.basis = Basis.IDENTITY.rotated(Vector3(1,0,0), ground_camera_inclination)
		
		if landing_shape_timer > 0:
			landing_shape_timer -= 1
			if landing_shape_timer == 0:
				collision_shape_g.set_deferred("disabled", false)
				collision_shape_z.set_deferred("disabled", true)
		#camera.transform.basis = Basis.IDENTITY.rotated(Vector3(1,0,0), ground_camera_inclination)
		
		#camera.transform.basis = Basis(Vector3(1,0,0), ground_camera_inclination) 
		transform.basis = Basis(ground_right, ground_up, -ground_forward)
	else:
		camera.transform.basis = Basis.IDENTITY.rotated(Vector3(1,0,0), ground_camera_inclination)
		
		#ground_camera_dazimuth = 0.0
		
	
	#accelerando_scalar.display(hud)
	#accelerando.step(delta)
	
	#cached_camera_forward = camera_forward()
	#camera_transform = get_node("Camera").global_transform
	
	if smack_cooldown2 > 0:
		smack_cooldown2 -= 1

	if ground_mode:
		ground_core(delta)
	
	
	if clue_timer == 0:
		clue(false)
		clue_timer = clue_rate
	else:
		clue_timer -= 1


func ground_core(delta):
	if GRAVITY.length() == 0.0:
		# 3rd law of motion
		# if gravity ever doesn't (exist or) point into the surface, back to freefall
		ground_mode_to_freefall()
		return
		
	
	assert(GRAVITY.length() > 0.0) # you can't be in ground mode with no gravity
	recompute_basis_due_to_change_in_up(-GRAVITY.normalized())
	ground_forward = -transform.basis.z
	ground_up = transform.basis.y
	ground_right = transform.basis.x
	
	# First, move
	# Second, snap or fall
	
	
	# stair pop
	#var stair = stairs_test()
	#if stair:
	#	snap_flag = false
	#	transform.origin += ground_up * stair
	#	transform.origin += 0.3 * ground_forward
	#else:
	#	snap_flag = true
	
	# MOVE
	#var total_weight = GRAVITY
	#var compression = total_weight.project(normal)
	#var tanga = total_weight - compression
	floormaster.forward = ground_forward
	floormaster.right = ground_right
	#floormaster.tanga = tanga
	floormaster.tanga = Vector3(0,0,0)
	#floormaster.compression_weight = compression_weight
	floormaster.step(delta)
	ground_velocity = floormaster.velocity
	if ground_velocity.length() > 0.0 && ray_cast(transform.origin, -ground_up):
		#var stair = stairs_test(ground_velocity * delta)
		#hud.present("stair", stair)
		#debug.put_line("stair", stair)
		var result_velocity = ice_colors_move_and_slide(ground_velocity, delta)
		floormaster.velocity = result_velocity
		#print(stair)

		#if(stair != 5.0):
			#print(stair)
			#transform.origin += -ground_up * (stair - 1.0) # snap down, stair up
	else:
		# no motion... this case is pointless
		#hud.present("stair", "...")
		var result_velocity = ice_colors_move_and_slide(ground_velocity, delta)
		floormaster.velocity = result_velocity
		
	
	# TODO did we deflect off a surface?
	
	
	# SNAP OR FALL
	var info = ray_cast(transform.origin, -ground_up)
	if info:
		ground_normal = info.normal
		#hud.present("ground angle", rad2deg(ground_normal.angle_to(ground_up)))
		var standoff = (info.position - transform.origin).length()
		var kludge = ground_normal.angle_to(ground_up)
		var target = 1.0 + 0.5 * tan(kludge * 3.0 / PI)
		if standoff < (target - 0.01) || standoff > (target + 0.01):
			transform.origin = info.position + ground_up * target
			#transform.origin += (1.0 - standoff) * ground_up
		if ground_normal.angle_to(ground_up) > PI/3:
			ground_mode_to_freefall()
	else:
		#hud.present("ground normal", "...")
		ground_mode_to_freefall()

### AIR MODE
func _integrate_forces(state : PhysicsDirectBodyState):
	if ground_mode:
		var ns = get_contact_normals(state)
		tracked_surfaces.clear()
		for n in ns:
			tracked_surfaces.push_back(n)
		#hud.present("surfaces", tracked_surfaces)
	else:
		freefall_core(state)

func freefall_core(state : PhysicsDirectBodyState):
	state.angular_velocity *= 0.97
	#debug.put_line("target=%f, current=%f", )
	
	var delta = state.step
	var omega = state.transform.basis.xform_inv(state.angular_velocity)
	omega.y += -mouse_yaw * delta * 100.0
	
	#if mouse_pitch: print("mouse_pitch", mouse_pitch)
	#hud.present("inclination", ground_camera_inclination)
	if mouse_is_undoing_inclination(mouse_pitch):
		var pitch_remainder = undo_inclination(mouse_pitch)
		omega.x += pitch_remainder * delta * 100.0
	else:
		omega.x += mouse_pitch * delta * 100.0
	
	#if !jump_mode: omega.x += -mouse_pitch * delta * 100.0
	#if jump_mode: ground_camera_inclination += -mouse_pitch
	omega.z += -mouse_roll * delta * 100.0
	mouse_yaw = 0.0
	mouse_pitch = 0.0
	mouse_roll = 0.0
	state.angular_velocity = state.transform.basis.xform(omega)
	
	
	
	#print(axis)
	
	# in freefall mode we use RIGID or CHARACTER mode. Which means the code
	# needs to set linear_velocity and angular_velocity in the state to achieve
	# what we want. It's possible to teleport state.transform.origin, at least
	# occasionally.
	
	var ns = get_contact_normals(state)
	var vs = get_contact_velocities(state)
	var ps = get_contact_points(state)
	
	tracked_surfaces.clear()
	for n in ns:
		tracked_surfaces.push_back(n)
	#hud.present("surfaces", tracked_surfaces)
	
	if ns.empty():
		smack_cooldown = false
	else: # you're in contact
		if smack_cooldown == false:
			smack_cooldown = true

			emit_signal("smacked_surface", {
				"points": ps,
				"normals": ns,
				"velocities": vs
			})

	var v = state.linear_velocity
	v += jetpack * -state.transform.basis.z * 2.0 * delta
	v += jetpackUD * state.transform.basis.y * 2.0 * delta
	v += GRAVITY * delta
	if !nbos.empty():
		#var effort = abs(control[0])+abs(control[1])
		v += control[0] * -state.transform.basis.z * 5.0 * delta
		v += control[1] *  state.transform.basis.x * 5.0 * delta
		#v += effort * state.transform.basis.y * 10.0 * delta
	if deferred_jump:
		v += deferred_jump.normal * deferred_jump.strength
		state.transform.origin += deferred_jump.normal * 0.1
		deferred_jump = null
	if bump_force:
		state.transform.origin += bump_force.normalized() * 0.5
		bump_force = Vector3(0,0,0)

	set_linear_velocity(v)
	ground_velocity = v

var mouse_pitch = 0.0
var mouse_yaw = 0.0
var mouse_roll = 0.0

func mouse_horiz(dx):
	#clue(true)
	if ground_mode:
		#ground_camera_azimuth -= dx/400.0
		ground_forward = ground_forward.rotated(ground_up, -dx/400.0)
		ground_right = ground_forward.cross(ground_up)
		floormaster.chdir(ground_forward, ground_right)
		#camera.rotate_y(-dx / 400.0)
	else:
		mouse_yaw += dx/200.0
		#target_attitude = target_attitude.rotated(transform.basis.y, -dx/200.0)

func mouse_verti(dy):
	#clue(true)
	if ground_mode:
		ground_camera_inclination -= dy/400.0
		#camera.rotate_x(-dy / 400.0)
		pass
	else:
		mouse_pitch -= dy/200.0
		#target_attitude = target_attitude.rotated(transform.basis.x, -dy/200.0)

func mouse_roll(dz):
	if ground_mode: return
	mouse_roll += dz/200.0
	#target_attitude = target_attitude.rotated(transform.basis.z, -dz/200.0)
	
func enable_sprint(flag):
	floormaster.chspeed(RUN if flag else WALK)
		
func updated_control(zx):
	control = zx
	floormaster.ctrl(zx)
	jetpack = zx[0]

func execute_jump():
	if feet_status:
		deferred_jump = {"normal": feet_status.normal, "strength": JUMP}
		if ground_mode:
			ground_mode_to_freefall()

func updown_control(value):
	jetpackUD = value

var save_state = null
func press_H():
	#room_spin = 0.0 if room_spin else 1.0
	GRAVITY = Vector3() if GRAVITY else Vector3(0,-10,0)
	pass
	#var mat = get_node("MeshInstance").get_surface_material(0)
	#mat.albedo_color = Color(1,1,0)
	#pass
	#room_spin = 0.0 if room_spin else 1.0



# move along the motion, return null if no collision
# otherwise return travel vector, remainder vector, and collision normal
func move_and_collide(motion, infinite_inertia):
	var result = PhysicsTestMotionResult.new()
	var collision = PhysicsServer.body_test_motion(get_rid(), global_transform, motion, infinite_inertia, result)
	if collision:
		transform.origin += result.motion
		return {
			"travel": result.motion,
			"remainder": result.motion_remainder,
			"normal": result.collision_normal
		}
	else:
		transform.origin += motion
		return null

#var on_floor
func ice_colors_move_and_slide(
		var lv,
		var delta,
		var floor_direction = Vector3(0,1,0), 
		var max_slides = 4, 
		var slope_stop_min_velocity = 0.05, 
		var floor_max_angle = deg2rad(45)
	):
	var motion = lv * delta
	#on_floor = false
	while(max_slides):
		var collision = move_and_collide(motion, true)
		if collision:
			motion = collision.remainder
			#on_floor = true
			if (collision.normal.dot(floor_direction) >= cos(floor_max_angle)):
				var hor_v = lv - floor_direction * floor_direction.dot(lv)
				if collision.travel.length() < 0.05 and hor_v.length() < slope_stop_min_velocity:
					transform.origin -= collision.travel
					return Vector3.ZERO
			var n = collision.normal
			motion = motion.slide(n)
			lv = lv.slide(n)
		else:
			break
		max_slides -= 1
		if motion.length() == 0:
			break
	return lv



### UTILS
func average3(vs):
	var sum = Vector3(0,0,0)
	for v in vs:
		sum += v
	return sum / vs.size()

# A = C * B -- technically works but gives a random one of two directions
func matrix_diff(A, B):
	var C = A * B.transposed()
	return C

func matrix_axis(A):	
	var C = matrix_diff(A, Basis.IDENTITY)
	var q = C.get_rotation_quat()
	var axis = Vector3(q.x, q.y, q.z).normalized()
	return axis







# which way is up assuming you are on a surface
func which_way_is_up(normal):
	assert(GRAVITY.length() > 0.0)
	return -GRAVITY.normalized()

# if forward and new_up are parallel, a random direction needs to be picked perpendicular to them
# this routine may have bugs and needs to be verified
func recompute_basis_due_to_change_in_up(new_up):
	var old_basis = transform.basis
	if new_up.length_squared() < 0.001:
		print("new up is messed up")
		print("new_up ", new_up)
		get_tree().quit()
	var forward = transform.basis.z
	if abs(forward.dot(new_up)) > 0.99:
		var random_forwardish = forward + Vector3(1,0,0)
		forward = (random_forwardish - random_forwardish.project(new_up)).normalized()
	else:
		forward = (forward - forward.project(new_up)).normalized()
	var up = new_up
	var right = up.cross(forward)
	transform.basis = Basis(right, up, forward)
	return transform.basis


class Accelerando:
	var x = 0.0
	var v = 0.0
	var k = 2.0
	
	var direction = Vector3(0,0,0)

	func step(delta):
		if x > 0.0 || v > 0.0:
			var vdot = -k*x
			v += vdot * delta
			x += v * delta
			if x < 0.0:
				x = 0.0
	
	func impulse(amount):
		v += amount
		x += 0.01
	
	func get_value():
		return x
	
	func set_direction(d):
		direction = d
	
	func get_acceleration():
		return x * direction
		
	func display(hud):
		hud.set_display([x,v])


class Floormaster:
	#var friction_k = 1.0 # depends on surface / shoes
	var sliding_k = 0.1  # depends on surface / shoes
	var velocity = Vector3(0,0,0) # read this
	var target_velocity = Vector3(0,0,0) # internal
	#var compression_weight = Vector3(0,0,0) # set this
	var forward = Vector3(0,0,-1) # set this with method
	var right = Vector3(1,0,0) # set this with method
	var control = Vector2(0,0) # set this with method
	var max_speed = 1.0 # set this with method
	var tanga = Vector3(0,0,0) # set this
	var tanga_reduction = 1.0
	var sliding = true
	
	func step(delta):
		var remaining_tanga
		if tanga.length() > tanga_reduction:
			remaining_tanga = tanga - tanga*tanga_reduction
		else:
			remaining_tanga = tanga
		
		if sliding:
			var required = target_velocity - velocity
			var increment = required * sliding_k
			if increment.length() > required.length():
				velocity = target_velocity + tanga*delta
			else:
				velocity += increment + tanga*delta
		else:
			velocity = target_velocity
	
	func update_target():
		target_velocity = 10.0 * max_speed * (forward * control[0] + right * control[1])
		
	func ctrl(xz):
		control = xz
		update_target()

	func chdir(f,r):
		forward = f
		right = r
		update_target()
	
	func chspeed(s):
		max_speed = s
		update_target()


class CameraUndisorientator:
	var old_basis = Basis.IDENTITY
	var new_basis = Basis.IDENTITY
	var param = 1.0
	
	func undisorientate(old, new):
		old_basis = old
		new_basis = new
		param = 0.0

	func step(delta):
		if param < 1.0:
			param += delta * 8.0
			if param > 1.0:
				param = 1.0
	
	func current_matrix():
		return old_basis.slerp(new_basis, param)

# you got your surfaces you're in contact with
# can any of them support ground mode. bogus because we don't get the angles.
# angles are bogus since we havijnalskjd rlsaoka 
func surfaces_compression(normals, gravity):
	var results = []
	for n in normals:
		var g_normal = gravity.project(n)
		var mag = g_normal.dot(n)
		results.push_back(max(0.0, mag))


"""
# if ray cast fails but we are touching some surface, return a lateral vector away from the ledge
# on some geometries using this lateral for a push will be chaos
func the_edge_test():
	var down = -transform.basis.y
	var result = ray_cast(transform.origin, down)
	if !result and feet_status:
		var space = PhysicsServer.space_get_direct_state(get_world().space)
		edge_tester.test(transform.origin, transform.basis, get_rid(), space)
		var sum = Vector3.ZERO
		for r in edge_tester.results:
			sum += r
		return sum
		#var i = 0
		#for r in edge_tester.results:
			#debug.put_line("edge test", "result %d %s" % [i, str(r)])
			#i += 1
	else:
		return null
"""

"""
class EdgeTester:
	var no_points = 8
	var offsets = []
	var laterals = []
	var results = []

	func _init():
		for i in range(0,no_points):
			var angle = 2*PI / no_points * i
			var lateral = Vector3(1,0,0).rotated(Vector3(0,1,0), angle)
			offsets.push_back(lateral)
			laterals.push_back(-lateral)
	
	func test(origin, basis, my_rid, space):
		var down = -basis.y
		#var space = PhysicsServer.space_get_direct_state(get_world().space)
		results.clear()
		for i in range(0,no_points):
			var result = ray_cast(origin + 0.5*basis.xform(offsets[i]), basis.xform(down), my_rid, space)
			if result:
				results.push_back(basis.xform(laterals[i]))
			else:
				results.push_back(Vector3(0,0,0))

	func ray_cast(origin, vector, my_rid, space):
		var from = origin
		var to = origin + vector * 2
		return space.intersect_ray(from, to, [my_rid])
"""


# if center down ray cast finds something, then we might be on stairs
# in that case use this to figure out the right height to stand at.
# this test is only used for motion, not standing still.
# returns the vertical distance from player center to the stair to stand on
func stairs_test(motion):
	var space = PhysicsServer.space_get_direct_state(get_world().space)
	var down = -transform.basis.y
	var ahead = motion.normalized()
	var offset = down * 0.8
	
	var point1 = transform.origin + offset
	var point2 = transform.origin + offset + ahead * 0.55
	
	var result1 = space.intersect_ray(point1, point1 + 1*down, [get_rid()])
	var result2 = space.intersect_ray(point2, point2 + 1*down, [get_rid()])
	
	# according to assumptions, result1 and 2 both don't fail, but
	if !result1 || !result2: return 5.0 # so it's obvious something's wrong
	
	var level1 = (result1.position - transform.origin).project(down).length()
	var level2 = (result2.position - transform.origin).project(down).length()
	
	if level1 > level2: # going up
		return level2
	elif level2 > level1: # going down
		return level1
	else: return level1


func mouse_is_undoing_inclination(mouse_pitch):
	if ground_camera_inclination == 0.0: return false
	else: return mouse_pitch * ground_camera_inclination < 0.0
	
func undo_inclination(mouse_pitch):
	if abs(mouse_pitch) < abs(ground_camera_inclination):
		ground_camera_inclination += mouse_pitch
		return 0.0
	else:
		var remainder = ground_camera_inclination + mouse_pitch
		ground_camera_inclination = 0.0
		return remainder

func synthetic_inclination(old_forward, new_up):
	#print("compute synthetic inclination old forward=", old_forward, " new_up=", new_up)
	var right = old_forward.cross(new_up)
	if abs(old_forward.dot(new_up)) > 0.995:
		var random = (Vector3(1,2,3) * new_up).normalized()
		old_forward = (old_forward + random).normalized()
		right = old_forward.cross(new_up)
		#print("parallel!... fixing, old forward =", old_forward)
	var new_forward = (old_forward - old_forward.project(new_up)).normalized()
	var angle = new_forward.signed_angle_to(old_forward, right.normalized())
	#print("computed new_forward=", new_forward, " right=", right, " angle=", angle)
	return angle

"""
func overwrite_state(info):
	mode = info.rigidbody_mode
	transform.origin = info.position
	transform.basis = info.attitude
	linear_velocity = info.velocity
	ground_velocity = info.velocity
	angular_velocity = info.angular_velocity
	ground_mode = info.ground_mode
	ground_camera_inclination = info.ground_camera_inclination
	control = info.control
	RUN = info.RUN

func dump_state():
	return {
		"position": transform.origin,
		"velocity": linear_velocity,
		"attitude": transform.basis,
		"angular_velocity": angular_velocity,
		"ground_mode": ground_mode,
		"ground_camera_inclination": ground_camera_inclination,
		"ground_velocity": ground_velocity,
		"control": control,
		"RUN": RUN,
		"rigidbody_mode": mode
	}
"""

var my_shadow
var clue_counter = 0
var mouse_limiter = 0
func clue(is_mouse):
	if mouse_limiter > 0: mouse_limiter -= 1
	if is_mouse && mouse_limiter > 0: return
	if is_mouse && mouse_limiter == 0: mouse_limiter = 10
		
	clue_counter += 1
	var frame_no = get_tree().get_frame()
	var cps = 60.0 * float(clue_counter) / frame_no
	#print("cps ", cps )
	#print("clue ", clue_counter)
	if hud:
		hud.present("clues", clue_counter)
	#hud.present("cf4", control_flag4)
	
	if my_shadow == null: return
	my_shadow.rpc("deliver_future_state", frame_no, {
		"position": transform.origin,
		"velocity": linear_velocity,
		"attitude": transform.basis,
		"omega": angular_velocity,
		"center_of_orbit": null,
		"radius_of_orbit": Vector3(),
		"ambient_acceleration": GRAVITY,
		"inclination": ground_camera_inclination
	})



func is_pot(n):
	if n <= 0: return false
	if n == 1: return true
	while true:
		if n == 2: return true
		var r = n % 2
		if n > 2 && r > 0: return false
		n /= 2



