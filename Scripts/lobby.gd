extends Control

# Mapeamento exato dos nós da sua cena
@onready var label_sala = $MarginContainer/VBoxContainer/sala
@onready var p1_name = $MarginContainer/VBoxContainer/panelHost/contHost/hostName
@onready var p1_status = $MarginContainer/VBoxContainer/panelHost/contHost/hostStatus
@onready var p2_name = $MarginContainer/VBoxContainer/panelP2/contP2/p2Name
@onready var p2_status = $MarginContainer/VBoxContainer/panelP2/contP2/p2Status
@onready var btn_pronto = $MarginContainer/VBoxContainer/Button

func _ready() -> void:
	# 1. Configuração inicial (Limpando os textos provisórios do editor)
	label_sala.text = "SALA: " + Firebase.current_room
	p1_name.text = Session.user_id
	p1_status.text = "Aguardando..."
	p2_name.text = "Aguardando oponente..."
	p2_status.text = ""
	
	# 2. Conectar o clique do botão
	btn_pronto.pressed.connect(_on_btn_pronto_pressed)
	
	# 3. Conectar o sinal do Firebase
	Firebase.room_updated.connect(_on_room_updated)
	
	# 4. Iniciar a escuta do banco de dados
	Firebase.start_listening(Firebase.current_room, Session.user_id)

func _on_btn_pronto_pressed() -> void:
	btn_pronto.disabled = true
	btn_pronto.text = "Aguardando outro jogador..."
	
	# Atualiza o status visualmente para o jogador local
	p1_status.text = "PRONTO"
	p1_status.modulate = Color(0, 1, 0) # Fica verde
	
	# Envia a informação para o banco
	Firebase.set_ready(Firebase.current_room, Session.user_id)

func _on_room_updated(data: Dictionary) -> void:
	# Aqui preparamos a lógica de atualizar a tela quando o Firebase responder
	if data.has("players"):
		var players = data["players"].keys()
		
		# Se tiver mais de um jogador na sala, preenchemos o Painel 2
		if players.size() > 1:
			for player_id in players:
				if player_id != Session.user_id:
					p2_name.text = player_id
					p2_status.text = "Conectado"
	
	# Atualiza o status de "Pronto" do oponente
	if data.has("ready"):
		var ready_players = data["ready"]
		if ready_players.has(p2_name.text) and ready_players[p2_name.text] == true:
			p2_status.text = "PRONTO"
			p2_status.modulate = Color(0, 1, 0)
			
	# Se a sala mudar para estado de combate, inicia o jogo
	if data.has("state") and data["state"] == "combat":
		get_tree().change_scene_to_file("res://Scenes/game.tscn")
