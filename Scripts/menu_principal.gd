extends Node2D



func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_createroom_button_pressed() -> void:
	$PanelCreateroom.visible = true
	$CreateroomButton.visible = false
	$JoinroomButton.visible = false



func _on_joinroom_button_pressed() -> void:
	$PanelJoinroom.visible = true
	$CreateroomButton.visible = false
	$JoinroomButton.visible = false

func _on_leavecreate_button_pressed() -> void:
	leave_menu()

func _on_leavejoin_button_pressed() -> void:
	leave_menu()

func leave_menu():
	$PanelJoinroom.visible = false
	$PanelCreateroom.visible = false
	$CreateroomButton.visible = true
	$JoinroomButton.visible = true
	$PanelJoinroom/JoinroomnameInput.text = ""
	$PanelJoinroom/JoinroompassInput.text = ""
	$PanelCreateroom/CreateroomnameInput.text = ""
	$PanelCreateroom/CreateroompassInput.text = ""
	


func _on_create_button_pressed() -> void:
	var room_name = $PanelCreateroom/CreateroomnameInput.text
	var room_pass = $PanelCreateroom/CreateroompassInput.text
	
	if room_name == "":
		print("Nome da sala vazio!")
		return
	
	var player_id = Session.user_id # ou email
	
	print("ROOM:", room_name)
	print("PLAYER:", player_id)
	
	$Firebase.create_room(room_name, player_id, room_pass)
	
	print("Sala criada!")



func _on_join_button_pressed() -> void:
	var room_name = $PanelJoinroom/JoinroomnameInput.text
	var room_pass = $PanelJoinroom/JoinroompassInput.text
	
	var player_id = Session.user_id
	
	$Firebase.try_join_room(room_name, player_id, room_pass)
	
	
