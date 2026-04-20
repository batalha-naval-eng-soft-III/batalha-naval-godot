extends Node

var base_url = "https://battleship-multiplayer-cc51c-default-rtdb.firebaseio.com/"

var listening := false
var current_room := ""
var my_id := ""

var poll_interval := 4
var polling_active := false


# -------------------------
# ROOM FUNCTIONS
# -------------------------

func create_room(room_id: String, player_id: String):
	var url = base_url + "rooms/" + room_id + ".json"

	var data = {
		"players": {
			player_id: true
		},
		"state": "waiting",
		"turn": player_id
	}

	_send_request(url, HTTPClient.METHOD_PUT, data)


func join_room(room_id: String, player_id: String):
	var url = base_url + "rooms/" + room_id + "/players/" + player_id + ".json"

	var data = true

	_send_request(url, HTTPClient.METHOD_PUT, data)


func update_room_state(room_id: String, data: Dictionary):
	var url = base_url + "rooms/" + room_id + ".json"
	_send_request(url, HTTPClient.METHOD_PATCH, data)


func set_turn(room_id, player_id):
	var url = base_url + "rooms/" + room_id + "/turn.json"

	var data = JSON.stringify(player_id)

	_send_request(url, HTTPClient.METHOD_PUT, data)


func set_ready(room_id, player_id):
	var url = base_url + "rooms/" + room_id + "/ready/" + player_id + ".json"

	_send_request(url, HTTPClient.METHOD_PUT, true)


func send_attack(room_id, player_id, cells, attack_type):
	var url = base_url + "rooms/" + room_id + "/action.json"

	var data = {
		"type": "attack",
		"from": player_id,
		"cells": cells,
		"attack_type": attack_type
	}

	_send_request(url, HTTPClient.METHOD_PUT, data)


# -------------------------
# HTTP CORE
# -------------------------

func _send_request(url: String, method: int, data):
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(result, response_code, headers, body):
		print("Firebase response:", response_code)

		if body:
			print(body.get_string_from_utf8())

		http.queue_free()
	)

	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]

	http.request(url, headers, method, json)


# -------------------------
# LISTENER SYSTEM
# -------------------------

func start_listening(room_id: String, player_id: String):
	current_room = room_id
	my_id = player_id
	listening = true

	if polling_active:
		return

	polling_active = true
	_poll_room()


func stop_listening():
	listening = false
	polling_active = false


func _poll_room():
	while polling_active and listening:
		await get_tree().create_timer(poll_interval).timeout
		_request_room()


func _request_room():
	var url = base_url + "rooms/" + current_room + ".json"

	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(result, code, headers, body):
		var data = JSON.parse_string(body.get_string_from_utf8())

		if data != null:
			_handle_room_update(data)

		http.queue_free()
	)

	http.request(url)


# -------------------------
# ROOM HANDLER
# -------------------------

func _handle_room_update(data):

	# TURN SYSTEM
	if data.has("turn"):
		if data["turn"] != my_id:
			print("NÃO É SUA VEZ")
		else:
			print("SUA VEZ")

	# STATE
	if data.has("state"):
		print("STATE:", data["state"])

	# PLAYERS
	if data.has("players"):
		print("PLAYERS:", data["players"])

	# READY SYSTEM
	if data.has("ready"):
		print("READY:", data["ready"])

	# ACTION SYSTEM (ATAQUES)
	if data.has("action"):
		if data["action"] != null:
			if data["action"]["from"] != my_id:
				print("ATAQUE RECEBIDO DO OPONENTE")

	# DEBUG
	print("ROOM UPDATE RECEIVED")
