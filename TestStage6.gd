extends Spatial

var hud
var debug

var server_color = Color(0.5,0,0,1)
var client_color = Color(0,0.5,0,1)

func _ready():
	hud = get_node("CanvasLayer/HUD")
	debug = get_node("CanvasLayer/DebugPrinter")
	
	hud.present("key", "M=server N=client")
	
	
	"""
	var spawn_location = get_node("SpawnPoint").translation
	var shadow = get_node("ShadowFactory").create_shadow(spawn_location)
	var player = get_node("PlayerFactory").create_player(shadow, hud, debug)
	add_child(shadow)
	add_child(player)
	player.get_node("Camera").current = true
	get_node("DangerCam").current = false
	"""
	

	
func on_peer_connected(peer_id):
	debug.put_line("multiplayer", "%d has connected" % peer_id)
	
	var spawn_location = get_node("SpawnPoint").translation
	var their_shadow = get_node("ShadowFactory").create_shadow(peer_id, spawn_location, client_color, get_node("Players"))
	
	var my_peer_id = get_tree().get_network_unique_id()
	var my_shadow = get_node("Players").get_node(str(my_peer_id))
	debug.put_line("sending them my state. peer_id", my_peer_id)
	rpc("here_i_am", my_shadow.dump_state())

func on_peer_disconnected(peer_id):
	debug.put_line("multiplayer", "%d has disconnected" % peer_id)
	get_node("Players").get_node(str(peer_id)).queue_free()

func on_connected_to_server():
	var my_peer_id = get_tree().get_network_unique_id()
	debug.put_line("multiplayer", "connected to server as %d" % my_peer_id)
	
	var spawn_location = get_node("SpawnPoint").translation
	var shadow = get_node("ShadowFactory").create_shadow(my_peer_id, spawn_location, client_color, get_node("Players"))
	var player = get_node("PlayerFactory").create_player(my_peer_id, shadow, hud, debug, spawn_location)
	shadow.visible = false
	player.name = "Player"
	add_child(player)
	player.get_node("Camera").current = true
	get_node("DangerCam").current = false
	
	# we need to spawn a ghost at the location of the "server character"

remote func here_i_am(info):
	var their_peer_id = get_tree().get_rpc_sender_id()
	debug.put_line("they send me some state, I got it? (their) peer_id", their_peer_id)
	var shadow = get_node("ShadowFactory").create_shadow(their_peer_id, info.position, server_color, get_node("Players"))
	shadow.restore_state(info)

func on_connection_failed():
	debug.put_line("multiplayer", "connection failed")
	net_mode = "offline"
	get_tree().disconnect("connected_to_server", self, "on_connected_to_server")
	get_tree().disconnect("connection_failed",   self, "on_connection_failed")
	get_tree().disconnect("server_disconnected", self, "on_server_disconnected")

func on_server_disconnected():
	debug.put_line("multiplayer", "server disconnected (you)")
	get_node("Players").get_node("1").queue_free()
	net_mode = "offline"
	get_tree().disconnect("connected_to_server", self, "on_connected_to_server")
	get_tree().disconnect("connection_failed",   self, "on_connection_failed")
	get_tree().disconnect("server_disconnected", self, "on_server_disconnected")

var net_mode = "offline"
func start_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(10420, 8)
	get_tree().network_peer = peer
	get_tree().connect("network_peer_connected",    self, "on_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "on_peer_disconnected")
	net_mode = "server"
	
	var spawn_location = get_node("SpawnPoint").translation
	var shadow = get_node("ShadowFactory").create_shadow(1, spawn_location, server_color, get_node("Players"))
	var player = get_node("PlayerFactory").create_player(1, shadow, hud, debug, spawn_location)
	player.name = "Player"
	shadow.visible = false
	add_child(player)
	player.get_node("Camera").current = true
	get_node("DangerCam").current = false

func start_client():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client("localhost", 10420)
	debug.put_line("multiplayer", "attempting to connect to server. stand by...")
	get_tree().network_peer = peer
	get_tree().connect("connected_to_server",   self, "on_connected_to_server")
	get_tree().connect("connection_failed",   self, "on_connection_failed")
	get_tree().connect("server_disconnected", self, "on_server_disconnected")
	net_mode = "client"
	


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.scancode == KEY_M:
			if net_mode == "offline":
				start_server()
		elif event.scancode == KEY_N:
			if net_mode == "offline":
				start_client()
		elif event.scancode == KEY_ESCAPE:
				get_tree().quit()
