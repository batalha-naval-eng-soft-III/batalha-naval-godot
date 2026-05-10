extends Node2D

@onready var email_input = $MarginContainer/VBoxContainer/EmailInput
@onready var senha_input = $MarginContainer/VBoxContainer/SenhaInput
@onready var http = $HTTPRequest
var api_key = "AIzaSyDElepKQDGyA4-kHcLGNUrL8a2B9Buvdzo"
const SIZE = 10

var email_usuario = ""
var senha_usuario = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	http.request_completed.connect(_on_request_completed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func _criar_background() -> void:
	#for y in range(SIZE):
		#for x in range(SIZE):
			#var cell = preload("res://Scenes/Cell.tscn").instantiate()
			#
			#cell.x = x
			#cell.y = y
#
		#
	#pass

func _on_button_pressed() -> void:
	email_usuario = email_input.text.strip_edges()
	senha_usuario = senha_input.text
	print("Dados Armazenados")
	###Bater com dados de firebase
	


func _on_request_completed(result, response_code, headers, body):
	var response = JSON.parse_string(body.get_string_from_utf8())

	if response_code == 200:
		print("Login OK!")
		
		var id_token = response["idToken"]
		var local_id = response["localId"]

		Session.user_id = email_input.text.strip_edges().replace(".", "_").replace("@", "_")
		Session.token = id_token

		print("User ID:", local_id)
		print("Token:", id_token)

		get_tree().change_scene_to_file("res://Scenes/menu_principal.tscn")
	else:
		print("Erro:")
		print(response)


func _on_login_button_pressed() -> void:
	var email = email_input.text.strip_edges()
	var senha = senha_input.text

	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + api_key
		
	var headers = ["Content-Type: application/json"]
		
	var body = {
		"email": email,
		"password": senha,
		"returnSecureToken": true
	}
		
	var json = JSON.stringify(body)

	http.request(url, headers, HTTPClient.METHOD_POST, json)
