extends Control

@onready var label_sala = $MarginContainer/VBoxContainer/sala
@onready var p1_name = $MarginContainer/VBoxContainer/panelHost/contHost/hostName
@onready var p1_status = $MarginContainer/VBoxContainer/panelHost/contHost/hostStatus
@onready var p2_name = $MarginContainer/VBoxContainer/panelP2/contP2/p2Name
@onready var p2_status = $MarginContainer/VBoxContainer/panelP2/contP2/p2Status
@onready var btn_pronto = $MarginContainer/VBoxContainer/btnPronto
@onready var btn_sair = $MarginContainer/VBoxContainer/btnSair

func _ready() -> void:
	label_sala.text = "SALA: " + Firebase.current_room
	
	# Deixamos os textos carregando até o Firebase nos dizer quem é o dono da sala
	p1_name.text = "Carregando..."
	p1_status.text = "..."
	p2_name.text = "Aguardando oponente..."
	p2_status.text = "..."
	
	btn_pronto.pressed.connect(_on_btn_pronto_pressed)
	btn_sair.pressed.connect(_on_btn_sair_pressed)
	Firebase.room_updated.connect(_on_room_updated)
	Firebase.start_listening(Firebase.current_room, Session.user_id)

func _on_btn_pronto_pressed() -> void:
	btn_pronto.disabled = true
	btn_pronto.text = "Aguardando outro jogador..."
	
	# Checa em qual caixa você está para pintar o "PRONTO" verde instantaneamente
	if Session.user_id == p1_name.text:
		p1_status.text = "PRONTO"
		p1_status.modulate = Color(0, 1, 0)
	elif Session.user_id == p2_name.text:
		p2_status.text = "PRONTO"
		p2_status.modulate = Color(0, 1, 0)
	
	Firebase.set_ready(Firebase.current_room, Session.user_id)

func _on_room_updated(data: Dictionary) -> void:
	if data == null:
		print("A sala foi fechada pelo criador.")
		Firebase.stop_listening()
		get_tree().change_scene_to_file("res://Scenes/menu_principal.tscn")
		return
	# 1. Definir quem é o Host (Caixa Verde) e quem é o Convidado (Caixa Amarela)
	if data.has("turn"):
		var host_id = data["turn"] # Pega a ID do criador da sala
		p1_name.text = host_id
		
		# Se só tem um jogador, o host está aguardando
		if p1_status.text == "...": 
			p1_status.text = "Aguardando..."
		# 2. Descobrir quem é o outro jogador
		if data.has("players"):
			var players = data["players"].keys()
			if players.size() > 1:
				for player_id in players:
					if player_id != host_id:
						p2_name.text = player_id
						if p2_status.text == "...":
							p2_status.text = "Aguardando..."
			else:
				p2_name.text = "Aguardando oponente..."

	# 3. Atualizar quem já clicou em "Pronto"
	if data.has("ready"):
		var ready_players = data["ready"]
		
		# Atualiza status do Jogador 1
		if ready_players.has(p1_name.text) and ready_players[p1_name.text] == true:
			p1_status.text = "PRONTO"
			p1_status.modulate = Color(0, 1, 0)
			
		# Atualiza status do Jogador 2
		if p2_name.text != "Aguardando oponente..." and ready_players.has(p2_name.text) and ready_players[p2_name.text] == true:
			p2_status.text = "PRONTO"
			p2_status.modulate = Color(0, 1, 0)
			
	# 4. Iniciar o Jogo
	if data.has("state") and data["state"] == "combat":
		get_tree().change_scene_to_file("res://Scenes/game.tscn")
		
# Detecta se o usuário tentou fechar a janela do jogo pelo Windows/Linux
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Firebase.leave_current_room()
		get_tree().quit() # Fecha o jogo de fato após avisar o banco
func _on_btn_sair_pressed() -> void:
	Firebase.leave_current_room()
	# Dá um pequeno delay de 0.5s só para garantir que a requisição DELETE foi enviada
	await get_tree().create_timer(0.5).timeout 
	get_tree().change_scene_to_file("res://Scenes/menu_principal.tscn")
