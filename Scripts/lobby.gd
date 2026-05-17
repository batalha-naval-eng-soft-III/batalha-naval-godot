extends Control

# ==========================================
# CAMINHOS DOS NÓS (Corrigidos para o seu layout exato)
# ==========================================
@onready var label_sala = $MarginContainer/VBoxContainer/HBoxContainer2/sala
@onready var btn_sair = $MarginContainer/VBoxContainer/HBoxContainer2/btnSair

@onready var p1_name = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/panelHost/contHost/hostName
@onready var p1_status = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/panelHost/contHost/hostStatus
@onready var p2_name = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/panelP2/contP2/p2Name
@onready var p2_status = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/panelP2/contP2/p2Status
@onready var btn_pronto = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/btnPronto

# Caminhos das Configurações
@onready var btn_10x10 = $"MarginContainer/VBoxContainer/HBoxContainer/VBoxConfiguracoes/VBoxContainer3/HBoxContainer/10x10"

@onready var btn_menos_frota = $MarginContainer/VBoxContainer/HBoxContainer/VBoxConfiguracoes/VBoxContainer/HBoxContainer/btnMenos
@onready var btn_mais_frota = $MarginContainer/VBoxContainer/HBoxContainer/VBoxConfiguracoes/VBoxContainer/HBoxContainer/btnMais
@onready var lbl_frota = $MarginContainer/VBoxContainer/HBoxContainer/VBoxConfiguracoes/VBoxContainer/HBoxContainer/PanelContainer/Label

@onready var btn_menos_tempo = $MarginContainer/VBoxContainer/HBoxContainer/VBoxConfiguracoes/VBoxContainer2/HBoxContainer/btnMenos
@onready var btn_mais_tempo = $MarginContainer/VBoxContainer/HBoxContainer/VBoxConfiguracoes/VBoxContainer2/HBoxContainer/btnMais
@onready var lbl_tempo = $MarginContainer/VBoxContainer/HBoxContainer/VBoxConfiguracoes/VBoxContainer2/HBoxContainer/PanelContainer/Label

@onready var pane_config = $MarginContainer/VBoxContainer/HBoxContainer/VBoxConfiguracoes
# ==========================================
# VARIÁVEIS DE CONTROLE DAS CONFIGURAÇÕES
# ==========================================
var frota_atual: int = 4
var frota_min: int = 2
var frota_max: int = 8

var tempo_atual: int = 2
var tempo_min: int = 1
var tempo_max: int = 5

# ==========================================
# INICIALIZAÇÃO
# ==========================================
func _ready() -> void:
	label_sala.text = "SALA: " + Firebase.current_room
	
	p1_name.text = "Carregando..."
	p1_status.text = "..."
	p2_name.text = "Aguardando oponente..."
	p2_status.text = "..."
	
	if Firebase.is_host == false:
		pane_config.hide()
	# Exibe os valores iniciais na tela
	lbl_frota.text = str(frota_atual)
	lbl_tempo.text = str(tempo_atual) + " min"
	
	# Marca o botão 10x10 como pressionado por padrão, caso nenhum esteja
	btn_10x10.button_pressed = true
	
	# Conexões de Botões Principais
	btn_pronto.pressed.connect(_on_btn_pronto_pressed)
	btn_sair.pressed.connect(_on_btn_sair_pressed)
	
	# Conexões de Botões de Configuração
	btn_menos_frota.pressed.connect(_on_btn_menos_frota_pressed)
	btn_mais_frota.pressed.connect(_on_btn_mais_frota_pressed)
	btn_menos_tempo.pressed.connect(_on_btn_menos_tempo_pressed)
	btn_mais_tempo.pressed.connect(_on_btn_mais_tempo_pressed)
	
	# Conexão Firebase
	Firebase.room_updated.connect(_on_room_updated)
	Firebase.start_listening(Firebase.current_room, Session.user_id)

# ==========================================
# FUNÇÕES DOS BOTÕES DE CONFIGURAÇÃO (+ e -)
# ==========================================
func _on_btn_menos_frota_pressed() -> void:
	if frota_atual > frota_min:
		frota_atual -= 1
		lbl_frota.text = str(frota_atual)

func _on_btn_mais_frota_pressed() -> void:
	if frota_atual < frota_max:
		frota_atual += 1
		lbl_frota.text = str(frota_atual)

func _on_btn_menos_tempo_pressed() -> void:
	if tempo_atual > tempo_min:
		tempo_atual -= 1
		lbl_tempo.text = str(tempo_atual) + " min"

func _on_btn_mais_tempo_pressed() -> void:
	if tempo_atual < tempo_max:
		tempo_atual += 1
		lbl_tempo.text = str(tempo_atual) + " min"

# ==========================================
# FUNÇÕES DE MULTIPLAYER
# ==========================================
func _on_btn_pronto_pressed() -> void:
	btn_pronto.disabled = true
	btn_pronto.text = "Aguardando outro jogador..."
	
	if Session.user_id == p1_name.text:
		p1_status.text = "PRONTO"
		p1_status.modulate = Color(0, 1, 0)
	elif Session.user_id == p2_name.text:
		p2_status.text = "PRONTO"
		p2_status.modulate = Color(0, 1, 0)
	
	Firebase.set_ready(Firebase.current_room, Session.user_id)

func _on_room_updated(data) -> void:
	if data == null:
		print("A sala foi fechada pelo criador.")
		Firebase.stop_listening()
		get_tree().change_scene_to_file("res://Scenes/MenuPrincipal/MenuPrincipal.tscn") # <-- VERIFIQUE SE O CAMINHO ESTÁ CERTO
		return
		
	# 1. Definir Host e Convidado
	if data.has("turn"):
		var host_id = data["turn"]
		p1_name.text = host_id
		
		if p1_status.text == "...": 
			p1_status.text = "Aguardando..."
			
		# 2. Descobrir outro jogador
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
		
		if ready_players.has(p1_name.text) and ready_players[p1_name.text] == true:
			p1_status.text = "PRONTO"
			p1_status.modulate = Color(0, 1, 0)
			
		if p2_name.text != "Aguardando oponente..." and ready_players.has(p2_name.text) and ready_players[p2_name.text] == true:
			p2_status.text = "PRONTO"
			p2_status.modulate = Color(0, 1, 0)
			
		if ready_players.size() == 2:
			if Session.user_id == p1_name.text:
				if not (data.has("state") and data["state"] == "combat"):
					print("Ambos estão prontos! Host alterando estado e salvando configurações...")
					
					# Pega o texto do botão de tamanho de tabuleiro que estiver pressionado
					var tamanho_tab = "10x10"
					var btn_pressionado = btn_10x10.button_group.get_pressed_button()
					if btn_pressionado != null:
						tamanho_tab = btn_pressionado.text
					
					# Cria o pacote de informações
					var atualizacao = {
						"state": "combat",
						"config": {
							"board_size": tamanho_tab,
							"fleet_size": frota_atual,
							"turn_time": tempo_atual
						}
					}
					
					Firebase.update_room_state(Firebase.current_room, atualizacao)

	# 4. Iniciar o Jogo
	if data.has("state") and data["state"] == "combat":
		Firebase.stop_listening()
		get_tree().change_scene_to_file("res://Scenes/Jogo/Jogo.tscn") # <-- VERIFIQUE SE O CAMINHO ESTÁ CERTO

# ==========================================
# FUNÇÕES DE SAÍDA E ENCERRAMENTO
# ==========================================
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Firebase.leave_current_room()
		get_tree().quit()

func _on_btn_sair_pressed() -> void:
	Firebase.leave_current_room()
	await get_tree().create_timer(0.5).timeout 
	get_tree().change_scene_to_file("res://Scenes/MenuPrincipal/MenuPrincipal.tscn") # <-- VERIFIQUE SE O CAMINHO ESTÁ CERTO
