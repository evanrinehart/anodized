extends Node

func create_player(peer_id, shadow, hud, debug, spawn_location):
	var player_tmpl = preload("res://FPSTestChar.tscn")
	var player = player_tmpl.instance()
	player.my_shadow = shadow
	player.hud = hud
	player.debug = debug
	player.translation = spawn_location
	player.set_network_master(peer_id)
	return player
