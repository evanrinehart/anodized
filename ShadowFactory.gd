extends Node

func create_shadow(peer_id, spawn_location, color, container_node):
	var tmpl = preload("res://RemoteAvatar.tscn")
	var shadow = tmpl.instance()
	shadow.set_name(str(peer_id))
	shadow.set_network_master(peer_id)
	container_node.add_child(shadow)
	shadow.teleport(spawn_location)
	shadow.set_color(color)
	#shadow.visible = false
	return shadow
