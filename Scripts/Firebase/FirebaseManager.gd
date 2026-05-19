extends Node

signal room_updated(data)

var base_url = "https://battleship-multiplayer-cc51c-default-rtdb.firebaseio.com/"

var listening := false
var current_room := ""
var my_id := ""
var is_host := false

var poll_interval := 4
var polling_active := false


# -------------------------
# ROOM FUNCTIONS
# -------------------------

func create_room(room_id: String, player_id: String, password: String):
	var url = base_url + "rooms/" + room_id + ".json"

	var data = {
		"password": password,
		"players": {
			player_id: true
		},
		"state": "waiting",
		"turn": player_id
	}
	is_host = true
	_send_request(url, HTTPClient.METHOD_PUT, data)


func join_room(room_id: String, player_id: String):
	var url = base_url + "rooms/" + room_id + "/players/" + player_id + ".json"

	var data = true
	is_host = false
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
		var text = body.get_string_from_utf8()
		var data = JSON.parse_string(text)

		# Removemos o "if data != null" para que o valor nulo chegue ao handler
		_handle_room_update(data)

		http.queue_free()
	)

	http.request(url)


# -------------------------
# ROOM HANDLER
# -------------------------

func _handle_room_update(data):
	if data == null:
		print("A sala foi deletada no banco! Avisando as telas...")
		emit_signal("room_updated", null)
		return # Interrompe a função aqui para não quebrar as linhas de baixo
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
	emit_signal("room_updated", data)
	
	
func try_join_room(room_id: String, player_id: String, password: String):
	is_host = false
	var url = base_url + "rooms/" + room_id + ".json"

	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(result, code, headers, body):

		print("CODE:", code)

		if body == null:
			print("Body nulo")
			http.queue_free()
			return

		var text = body.get_string_from_utf8()
		print("BODY:", text)

		if text == "":
			print("Resposta vazia")
			http.queue_free()
			return

		var data = JSON.parse_string(text)

		if typeof(data) != TYPE_DICTIONARY:
			print("Sala não existe ou resposta inválida")
			http.queue_free()
			return

		if data.has("password") and data["password"] == password:
			print("Senha correta, entrando...")
			join_room(room_id, player_id)
		else:
			print("Senha incorreta")

		http.queue_free()
	)

	http.request(url)
func leave_current_room():
	if current_room == "" or my_id == "":
		return

	stop_listening()

	# Se for o Host, deleta a sala inteira (isso já limpa o nó 'ready' automaticamente)
	if is_host:
		var url = base_url + "rooms/" + current_room + ".json"
		_send_delete_request(url)
	else:
		# Se for o convidado, precisa deletar de dois lugares:
		# 1. Da lista de jogadores
		var url_player = base_url + "rooms/" + current_room + "/players/" + my_id + ".json"
		_send_delete_request(url_player)
		
		# 2. Da lista de 'ready' (Para resolver o seu segundo problema)
		var url_ready = base_url + "rooms/" + current_room + "/ready/" + my_id + ".json"
		_send_delete_request(url_ready)

	current_room = ""

# Função auxiliar para não repetir código de DELETE
func _send_delete_request(url: String):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		http.queue_free()
	)
	http.request(url, [], HTTPClient.METHOD_DELETE)

# Variável para controlar se o jogador está buscando partida rápida
var searching_quick_match := false

# -------------------------
# SISTEMA DE MATCHMAKING (PARTIDA RÁPIDA)
# -------------------------

func start_quick_match(player_id: String):
	searching_quick_match = true
	var url = base_url + "quick_queue.json"

	var http = HTTPRequest.new()
	add_child(http)
	
	# Usando bind para passar o player_id e o próprio nó http para o callback
	http.request_completed.connect(self._on_quick_queue_checked.bind(http, player_id))
	http.request(url)

func _on_quick_queue_checked(result, code, headers, body, http, player_id):
	http.queue_free()
	
	if not searching_quick_match:
		return # O jogador cancelou a busca antes da resposta chegar
		
	var text = body.get_string_from_utf8()
	var queue_data = JSON.parse_string(text) if text else null

	if typeof(queue_data) == TYPE_DICTIONARY and queue_data.size() > 0:
		# ACHOU ALGUÉM NA FILA!
		var host_id = queue_data.keys()[0]
		var room_to_join = queue_data[host_id]

		print("Oponente encontrado! Entrando na sala: ", room_to_join)

		# 1. Remove a sala da fila para que um terceiro jogador não tente entrar
		_send_delete_request(base_url + "quick_queue/" + host_id + ".json")

		# 2. Configura as variáveis locais
		current_room = room_to_join
		my_id = player_id
		is_host = false
		
		# 3. Entra na sala como jogador 2
		join_room(current_room, player_id)

		# 4. Força as configurações fixas e inicia o combate diretamente
		var fixed_config = {
			"state": "combat",
			"config": {
				"board_size": "10x10",
				"fleet_size": 4,
				"turn_time": 2
			}
		}
		# O update_room_state vai disparar o _handle_room_update no Host que estava aguardando
		update_room_state(current_room, fixed_config)
		
		# Inicia o listener para receber os ataques e turnos
		start_listening(current_room, player_id)

	else:
		# FILA VAZIA - CRIA UMA SALA E AGUARDA
		print("Fila vazia. Criando sala de partida rápida...")
		is_host = true
		my_id = player_id
		
		# Gera um ID único simples para a sala rápida
		var new_room_id = "qm_" + str(Time.get_unix_time_from_system()).replace(".", "")
		current_room = new_room_id

		# Cria a sala base (sem senha, já que é aleatório)
		create_room(new_room_id, player_id, "")

		# Adiciona o ID dessa sala na fila pública
		var url_queue = base_url + "quick_queue/" + player_id + ".json"
		_send_request(url_queue, HTTPClient.METHOD_PUT, new_room_id)

		# Fica escutando a sala. Quando o outro jogador entrar, ele vai mudar o state para "combat"
		start_listening(new_room_id, player_id)

func cancel_quick_match():
	searching_quick_match = false
	if is_host and current_room.begins_with("qm_"):
		# Tira da fila pública
		_send_delete_request(base_url + "quick_queue/" + my_id + ".json")
		# Deleta a sala criada
		leave_current_room()
