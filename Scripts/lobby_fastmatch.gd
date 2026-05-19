extends Control

@onready var lbl_status = $MarginContainer/VBoxContainer/sala # Ajuste o caminho conforme sua árvore
@onready var btn_cancelar = $MarginContainer/VBoxContainer/btnSair # Ajuste o caminho

func _ready() -> void:
	lbl_status.text = "Procurando adversário..."
	
	# Conecta o botão de cancelar
	btn_cancelar.pressed.connect(_on_btn_cancelar_pressed)
	
	# Conecta para escutar as atualizações do Firebase
	Firebase.room_updated.connect(_on_room_updated)
	
	# Inicia a busca usando a função que criamos no FirebaseManager
	Firebase.start_quick_match(Session.user_id)

func _on_room_updated(data) -> void:
	# Verifica se a sala mudou para o estado de combate (alguém entrou)
	if data != null and data.has("state") and data["state"] == "combat":
		lbl_status.text = "Adversário encontrado! Preparando o tabuleiro..."
		btn_cancelar.disabled = true # Impede o jogador de cancelar durante a transição
		
		# Desconecta o sinal para não causar bugs de múltiplas chamadas
		Firebase.room_updated.disconnect(_on_room_updated)
		
		# Aguarda 1.5 segundos para o jogador conseguir ler a mensagem
		await get_tree().create_timer(1.5).timeout
		
		# Vai para o jogo
		get_tree().change_scene_to_file("res://Scenes/Jogo/Jogo.tscn")

func _on_btn_cancelar_pressed() -> void:
	# Remove o jogador da fila e deleta a sala temporária
	Firebase.cancel_quick_match()
	Firebase.room_updated.disconnect(_on_room_updated)
	
	# Volta para o menu principal
	get_tree().change_scene_to_file("res://Scenes/MenuPrincipal/MenuPrincipal.tscn")

# Segurança: Se o jogador clicar no "X" da janela para fechar o jogo durante a busca
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Firebase.cancel_quick_match()
		get_tree().quit()
