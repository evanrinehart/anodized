class_name RemoteAvatar
extends KinematicBody

export var position = Vector3()
export var velocity = Vector3()
export var attitude = Basis()
export var omega = Vector3()

export(Vector3) var center_of_orbit = null
export var radius_of_orbit = INF
export var ambient_acceleration = Vector3()

export var inclination = 0.0
var camera


#var position_error = Vector3()
var position_tween
var inclination_tween
var attitude_error = Basis.IDENTITY

var queue = DelayedReactionQueue.new()

func _ready():
	camera = get_node("Camera")
	position = Vector3(0,1,0)

func _physics_process(delta):
	#var frame_no = get_tree().get_frame()
	#var info = queue.dequeue(frame_no)
	#if info:
	#restore_state(info)
		
	#print(get_tree().get_frame(), " velocity ", velocity)
	error_decay(delta)
	basic_collision(delta)
	extrapolate(delta)
	#print(position_error)
	transform.origin = position
	transform.basis = attitude_error * attitude
	camera.transform.basis = Basis(Vector3(1,0,0), inclination)

func extrapolate(delta):
	var acceleration = ambient_acceleration
	if center_of_orbit != null:
		var moment = center_of_orbit - position
		if moment.length_squared() > 0.01:
			var centripetal = velocity.length_squared() / moment.length()
			acceleration += centripetal * moment.normalized()
	
	if cast_motion(delta) && velocity.length() > 0.05:
		acceleration += -1.8 * velocity
	
	velocity += acceleration * delta
	position += velocity * delta
	
	omega *= 0.97
	if omega.length_squared() > 0.0:
		attitude = attitude.rotated(omega.normalized(), omega.length() * delta)

func basic_collision(delta):
	var result = cast_motion(delta)
	if result:
		#print(get_tree().get_frame(), "oof")
		velocity += -1.00 * velocity.project(result.collision_normal)
		ambient_acceleration -= ambient_acceleration.project(result.collision_normal)

func error_decay(delta):
	attitude_error = attitude_error.slerp(Basis.IDENTITY, 0.1)

func cast_motion(delta):
	var result = PhysicsTestMotionResult.new()
	var hit = PhysicsServer.body_test_motion(get_rid(), global_transform, velocity * delta, true, result)
	if hit: return result

func clear_dynamics():
	velocity = Vector3()
	omega = Vector3()
	ambient_acceleration = Vector3()
	center_of_orbit = null

func teleport(point):
	position = point

func set_color(c):
	var mat = SpatialMaterial.new()
	mat.albedo_color = c
	get_node("MeshInstance").set_surface_material(0, mat)

func dump_state():
	return {
		"position": position,
		"velocity": velocity,
		"attitude": attitude,
		"omega": omega,
		"center_of_orbit": center_of_orbit,
		"radius_of_orbit": radius_of_orbit,
		"ambient_acceleration": ambient_acceleration,
		"inclination": inclination
	}

# call this with new dynamics data and freefall mode will adjust accordingly
# doesn't work very well while walking
func restore_state(info):
	#var old_position = position
	#position = info.position
	position_tween = get_tree().create_tween()
	position_tween.tween_property(self, "position", info.position, 0.2)
	position_tween.set_trans(Tween.TRANS_CUBIC)
	#position = info.position
	
	velocity = info.velocity
	var old_attitude = attitude_error * attitude
	attitude = info.attitude
	attitude_error = old_attitude * attitude.transposed()
	#attitude_error = Basis.IDENTITY
	omega = info.omega
	center_of_orbit = info.center_of_orbit
	radius_of_orbit = info.radius_of_orbit
	ambient_acceleration = info.ambient_acceleration
	
	inclination_tween = get_tree().create_tween()
	inclination_tween.tween_property(self, "inclination", info.inclination, 0.2)
	#inclination_tween.set_trans(Tween.TRANS_CUBIC)
	#inclination = info.inclination

remotesync func deliver_future_state(frame_no, info):
	#queue.enqueue(frame_no + 0, info)
	restore_state(info)

var save_state
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.scancode:
				KEY_KP_8: velocity += 1 * -attitude.z
				KEY_KP_5: clear_dynamics()
				KEY_KP_4: omega += Vector3(0,1,0)
				KEY_KP_6: omega += Vector3(0,-1,0)
				KEY_KP_2: velocity += -1 * -attitude.z
				KEY_KP_1:
					var old = attitude
					attitude = Basis(Vector3(1,0,0), PI/6) * attitude
					attitude_error = attitude.transposed() * old
				KEY_KP_3:
					center_of_orbit = Vector3()
					radius_of_orbit = 5
				KEY_KP_ADD:
					save_state = dump_state()
				KEY_KP_SUBTRACT:
					restore_state(save_state)



# theory of operation. When states come in, they have a frame number.
# delay these by a number of frames and put them in the queue. Do the frames
# late and you'll hopefully have the information you need by that time.
class DelayedReactionQueue:
	var queue = []
	
	func dequeue(now):
		var N = 0
		for i in range(0,queue.size()):
			if queue[i].frame_no <= now: N += 1
			else: break
		if N > 0:
			var answer = queue[N-1].info
			queue = queue.slice(N,queue.size()-1)
			return answer
		else:
			return null

	func enqueue(frame_no, info):
		var new_queue = []
		for entry in queue:
			if entry.frame_no < frame_no:
				new_queue.push_back(entry)
			else:
				break
		new_queue.push_back({"frame_no": frame_no, "info": info})
		queue = new_queue

	func debug_print():
		for entry in queue:
			print("frame_no=", entry.frame_no, " info=", entry.info)
			


	"""
	var q = DelayedReactionQueue.new()
	q.enqueue(4, "apple")
	q.enqueue(5, "banana")
	q.enqueue(17, "frosty")
	q.enqueue(26, "syrup")
	q.debug_print()
	print("dequeueing 0 => ", q.dequeue(0))
	q.debug_print()
	print("dequeueing 5 => ", q.dequeue(5))
	q.debug_print()
	print("dequeueing 5 again=> ", q.dequeue(5))
	q.debug_print()
	print("dequeueing 17 => ", q.dequeue(17))
	q.debug_print()
	print("dequeueing 29 => ", q.dequeue(29))
	q.debug_print()
	print("dequeueing 29 again => ", q.dequeue(29))
	q.debug_print()
	print("dequeueing 37 again => ", q.dequeue(37))
	q.debug_print()
	"""
