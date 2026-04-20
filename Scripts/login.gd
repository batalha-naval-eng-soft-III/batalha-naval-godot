extends Node2D

@onready var email_input = $MarginContainer/VBoxContainer/EmailInput
@onready var senha_input = $MarginContainer/VBoxContainer/SenhaInput
const SIZE = 10

var email_usuario = ""
var senha_usuario = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _criar_background() -> void:
	for y in range(SIZE):
		for x in range(SIZE):
			var cell = preload("res://scenes/Cell.tscn").instantiate()
			
			cell.x = x
			cell.y = y

		
	pass

func _on_button_pressed() -> void:
	email_usuario = email_input.text.strip_edges()
	senha_usuario = senha_input.text
	print("Dados Armazenados")
	###Bater com dados de firebase
