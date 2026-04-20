extends Node

var peer

func host_game():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(7777)
	multiplayer.multiplayer_peer = peer

	print("HOST iniciado")

func join_game(ip):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, 7777)
	multiplayer.multiplayer_peer = peer

	print("Conectando...")
