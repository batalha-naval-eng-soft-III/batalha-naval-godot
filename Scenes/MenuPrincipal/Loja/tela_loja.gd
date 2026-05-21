extends Node2D
@onready var moeda_ouro_label = $CanvasLayer/MoedaOuro
@onready var moeda_gema_label = $CanvasLayer/MoedaGema
@onready var user_id = Session.token
var firestore_url = "https://firestore.googleapis.com/v1/projects/battleship-multiplayer-cc51c/databases/(default)/documents/users/"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Dispara a busca assim que a loja abre na tela
	obter_dados_firestore_rest()
	print(firestore_url)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_botao_voltar_tela_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MenuPrincipal/MenuPrincipal.tscn")
	
func obter_dados_firestore_rest() -> void:
	# 1. Recupera o UID guardado no seu Autoload global Session
	var uid_usuario = Session.uid
	
	# Fallback de segurança para testes locais via F6
	if uid_usuario == "":
		print("Nenhum usuário ativo na Session.")

	# 2. Concatena a URL base com o ID do documento do usuário
	var url_completa = firestore_url + uid_usuario
	
	# 3. Cria um nó HTTP dinamicamente para fazer o fetch do banco
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Conecta o sinal de término à função que vai processar os dados
	http_request.request_completed.connect(self._on_firestore_response)
	
	# Faz a requisição GET oficial ao banco
	var erro = http_request.request(url_completa, [], HTTPClient.METHOD_GET)
	if erro != OK:
		print("Erro ao tentar iniciar a requisição HTTP para o Firestore.")
		
func _on_firestore_response(result, response_code, headers, body) -> void:
	# Limpa o nó HTTP da memória após receber a resposta
	var http_node = get_child(get_child_count() - 1)
	if http_node is HTTPRequest:
		http_node.queue_free()
		
	if response_code == 200:
		var resposta_texto = body.get_string_from_utf8()
		var json_dados = JSON.parse_string(resposta_texto)
		
		# Verifica se a estrutura de campos (fields) retornada pelo Firebase é válida
		if json_dados and json_dados.has("fields"):
			var campos = json_dados["fields"]
			
			# Lendo o campo 'qtd_moedas' dentro do padrão REST do Firestore
			if campos.has("qtd_moedas") and campos["qtd_moedas"].has("integerValue"):
				var moedas = campos["qtd_moedas"]["integerValue"]
				moeda_ouro_label.text = str(moedas)
				
			# Lendo o campo 'qtd_gemas' dentro do padrão REST do Firestore
			if campos.has("qtd_gemas") and campos["qtd_gemas"].has("integerValue"):
				var gemas = campos["qtd_gemas"]["integerValue"]
				moeda_gema_label.text = str(gemas)
				
			print("Valores de Moedas e Gemas atualizados via API REST com sucesso.")
	elif response_code == 404:
		print("Erro 404: O documento com este UID não foi encontrado na coleção 'users'.")
	else:
		print("Erro ao conectar com o Firestore REST. Código de resposta: ", response_code)
