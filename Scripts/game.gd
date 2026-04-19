extends Node2D

@onready var board = $Board
@onready var enemy_board = $EnemyBoard
@onready var camera = $Camera2D
@onready var turn_label = $Camera2D/TurnLabel
@onready var bglabel = $Camera2D/BgLabel

var grid = []
var enemy_grid = []
const SIZE = 10
var next_ship_id = 1
var selected_cell = null
var selected_cells = []
var is_player_turn = true

enum ShipType {PIRATE, LIGHTHOUSE }
var selected_ship = null
enum AttackType {NONE, NORMAL, PIRATE_FURY, FLASHLIGHT}
enum GameState { PLACING, COMBAT }
var game_state = GameState.PLACING
var selected_attack = AttackType.NONE

func _ready():
	create_board()

func create_board():
	for y in range(SIZE):
		grid.append([])
		for x in range(SIZE):
			var cell = preload("res://scenes/Cell.tscn").instantiate()
			
			cell.x = x
			cell.y = y
			
			cell.connect("clicked", _on_cell_clicked)
			cell.connect("right_clicked", _on_cell_right_clicked)
			
			board.add_child(cell)
			grid[y].append(cell)
			
			
func create_enemy_board():
	for y in range(SIZE):
		enemy_grid.append([])
		for x in range(SIZE):
			var cell = preload("res://scenes/Cell.tscn").instantiate()
			
			cell.x = x
			cell.y = y
			
			cell.is_enemy = true 
			
			cell.connect("clicked", _on_enemy_cell_clicked)
			
			enemy_board.add_child(cell)
			enemy_grid[y].append(cell)

func _on_cell_clicked(x, y):
	if game_state != GameState.PLACING:
		return
	
	match selected_ship:
		ShipType.PIRATE:
			place_pirate_ship(x, y)
		ShipType.LIGHTHOUSE:
			place_lighthouse(x, y)

func can_place_pirate(x, y):
	for i in range(3):
		var nx = x + i
		var ny = y 
		
		if nx >= SIZE:
			return false
		
		if grid[ny][nx].state != grid[ny][nx].CellState.EMPTY:
			return false
	
	return true

func place_pirate_ship(x, y):
	if not can_place_pirate(x, y):
		print("Não pode colocar aqui")
		return
	
	var current_id = next_ship_id
	next_ship_id += 1
	
	for i in range(3):
		var cell = grid[y][x + i]
		cell.state = cell.CellState.SHIP
		cell.ship_part = i + 1
		cell.ship_id = current_id
		cell.ship_type = cell.ShipType.PIRATE
		cell.update_visual()

func attack(x, y):
	var cell = grid[y][x]
	
	if cell.state == cell.CellState.EMPTY:
		cell.state = cell.CellState.MISS
	elif cell.state == cell.CellState.SHIP:
		cell.state = cell.CellState.HIT
	
	cell.update_visual()
	

func _on_cell_right_clicked(x, y):
	if game_state == GameState.PLACING:
		remove_ship(x, y)

func remove_ship(x, y):
	var cell = grid[y][x]
	
	if cell.state != cell.CellState.SHIP:
		return
	
	var id = cell.ship_id
	
	for row in grid:
		for c in row:
			if c.ship_id == id:
				c.state = c.CellState.EMPTY
				c.ship_part = 0
				c.ship_id = -1
				c.update_visual()


func _on_start_button_pressed() -> void:
	game_state = GameState.COMBAT
	print("Modo combate iniciado")
	$StartButton.hide()
	create_enemy_board()
	place_enemy_ship_3x1(2,2)
	place_enemy_ship_3x1(5,3)
	place_enemy_ship_3x1(6,6)
	move_camera_to_enemy()
	$PirateshipButton.visible = false
	$LighthouseButton.visible = false
	await get_tree().create_timer(2).timeout
	update_turn_label()
	
func move_camera_to_enemy():
	var tween = create_tween()
	tween.tween_property(
		camera, 
		"position", 
		Vector2(42,-285), 
		1.0  # duração (segundos)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	
func place_enemy_ship_3x1(x, y):
	for i in range(3):
		var cell = enemy_grid[y][x + i]
		cell.state = cell.CellState.SHIP
		cell.ship_part = i + 1
		cell.ship_type = cell.ShipType.PIRATE
		
		

func _on_enemy_cell_clicked(x, y):
	if game_state != GameState.COMBAT:
		return
	
	if not is_player_turn:
		return
	
	if selected_attack == AttackType.NONE:
		print("Escolha um ataque primeiro!")
		return
	
	var cell = enemy_grid[y][x]
	
	if selected_attack == AttackType.NORMAL:
		select_cell(cell)
	elif selected_attack == AttackType.PIRATE_FURY:
		select_pirate_fury(cell)
	elif selected_attack == AttackType.FLASHLIGHT:
		select_flashlight(cell)
	
	cell.update_visual()

func select_cell(cell):
	# remove seleção anterior
	if selected_cell != null:
		selected_cell.set_selected(false)
	
	# define nova seleção
	selected_cell = cell
	selected_cell.set_selected(true)


func _on_attack_button_pressed() -> void:
	attack_selected()
	
func attack_selected():
	if selected_attack == AttackType.NONE:
		print("Nenhum ataque selecionado!")
		return
	
	match selected_attack:
		AttackType.NORMAL:
			if selected_cell == null:
				return
			perform_attack_on_cells([selected_cell])
		
		AttackType.PIRATE_FURY:
			if selected_cells.is_empty():
				return
			perform_attack_on_cells(selected_cells)
			
		AttackType.FLASHLIGHT:
			if selected_cells.is_empty():
				return
			perform_flashlight(selected_cells)
	
	selected_attack = AttackType.NONE
	reset_attack_buttons()
	
func enemy_attack():
	var x = randi() % SIZE
	var y = randi() % SIZE
	
	var cell = grid[y][x]
	
	while cell.state == cell.CellState.HIT or cell.state == cell.CellState.MISS:
		x = randi() % SIZE
		y = randi() % SIZE
		cell = grid[y][x]
	
	spawn_explosion(cell.global_position)
	
	if cell.state == cell.CellState.EMPTY:
		cell.state = cell.CellState.MISS
		cell.was_attacked_by_enemy = true
	elif cell.state == cell.CellState.SHIP:
		cell.state = cell.CellState.HIT
	
	cell.update_visual()
	
	await get_tree().create_timer(3).timeout
	
	move_camera_to_enemy()
	
	is_player_turn = true
	await get_tree().create_timer(1).timeout
	update_turn_label()
	
func move_camera_to_player():
	var tween = create_tween()
	tween.tween_property(
		camera,
		"position",
		Vector2(42, 205), 
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	
func spawn_explosion(pos):
	var explosion = preload("res://Scenes/explosion.tscn").instantiate()
	add_child(explosion)
	explosion.global_position = pos
	

func update_turn_label():
	if is_player_turn:
		turn_label.text = "SEU TURNO"
		bglabel.size.x = 25
	else:
		turn_label.text = "TURNO DO INIMIGO"
		bglabel.size.x = 40


func _on_cannonball_button_pressed() -> void:
	if is_player_turn == false:
		return
		
	if selected_attack == AttackType.NORMAL:
		selected_attack = AttackType.NONE
		reset_attack_buttons()
		clear_all_selection()
	else:
		clear_all_selection()
		selected_attack = AttackType.NORMAL
		reset_attack_buttons()
		$CannonballButton.modulate = Color(0.5, 1, 0.5)
	
func reset_attack_buttons():
	$CannonballButton.modulate = Color(1, 1, 1)
	$PiratefuryButton.modulate = Color(1, 1, 1)
	$FlashlightButton.modulate = Color(1, 1, 1)


func _on_piratefury_button_pressed() -> void:
	if is_player_turn == false:
		return
	if selected_attack == AttackType.PIRATE_FURY:
		selected_attack = AttackType.NONE
		reset_attack_buttons()
		clear_all_selection()
	else:
		clear_all_selection()
		selected_attack = AttackType.PIRATE_FURY
		reset_attack_buttons()
		$PiratefuryButton.modulate = Color(0.5, 1, 0.5)
		
	
func select_pirate_fury(center_cell):
	clear_all_selection()
	
	var cx = center_cell.x
	var cy = center_cell.y
	
	
	add_selected_cell(cx, cy)
	
	
	
	add_selected_cell(cx + 1, cy + 1)
	add_selected_cell(cx - 1, cy - 1)
	add_selected_cell(cx + 1, cy - 1)
	add_selected_cell(cx - 1, cy + 1)
		
func add_selected_cell(x, y):
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return
	
	var cell = enemy_grid[y][x]
	cell.set_selected(true)
	selected_cells.append(cell)
	
func perform_attack_on_cells(cells):

	var cells_copy = cells.duplicate()

	clear_all_selection()

	# usa a cópia daqui pra frente
	for cell in cells_copy:
		if cell.state == cell.CellState.EMPTY or cell.state == cell.CellState.SHIP:
			cell.state = cell.CellState.OBSERVED
			cell.update_visual()

	await get_tree().create_timer(1).timeout

	for cell in cells_copy:
		spawn_explosion(cell.global_position)
		
		if cell.ship_type == cell.ShipType.NONE:
			cell.state = cell.CellState.MISS
		else:
			cell.state = cell.CellState.HIT
		
		cell.update_visual()

	clear_all_selection()
	
	is_player_turn = false
	update_turn_label()
	
	await get_tree().create_timer(1.5).timeout
	move_camera_to_player()
	
	await get_tree().create_timer(2).timeout
	enemy_attack()
	

func clear_all_selection():
	if selected_cell != null:
		selected_cell.set_selected(false)
		selected_cell = null
	
	for cell in selected_cells:
		cell.set_selected(false)
	
	selected_cells.clear()


func _on_pirateship_button_pressed() -> void:
	selected_ship = ShipType.PIRATE


func _on_lighthouse_button_pressed() -> void:
	selected_ship = ShipType.LIGHTHOUSE
	

func can_place_lighthouse(x, y):
	if y - 1 < 0:
		return false
	
	if grid[y][x].state != grid[y][x].CellState.EMPTY:
		return false
	
	if grid[y - 1][x].state != grid[y - 1][x].CellState.EMPTY:
		return false
	
	return true
	
func place_lighthouse(x, y):
	if not can_place_lighthouse(x, y):
		return
	
	var current_id = next_ship_id
	next_ship_id += 1
	
	for i in range(2):
		var cell = grid[y - i][x]
		
		cell.state = cell.CellState.SHIP
		cell.ship_part = i + 1
		cell.ship_id = current_id
		cell.ship_type = ShipType.LIGHTHOUSE
		cell.ship_type = cell.ShipType.LIGHTHOUSE
		cell.update_visual()

func _on_flashlight_button_pressed() -> void:
	if is_player_turn == false:
		return
	
	if selected_attack == AttackType.FLASHLIGHT:
		selected_attack = AttackType.NONE
		reset_attack_buttons()
		clear_all_selection()
	else:
		clear_all_selection()
		selected_attack = AttackType.FLASHLIGHT
		reset_attack_buttons()
		$FlashlightButton.modulate = Color(0.5, 1, 0.5)
		
func select_flashlight(center_cell):
	clear_all_selection()
	
	var cx = center_cell.x
	var cy = center_cell.y
	
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			add_selected_cell(cx + dx, cy + dy)
			
			
func perform_flashlight(cells):
	for cell in cells:
		if cell.state == cell.CellState.EMPTY or cell.state == cell.CellState.SHIP:
			cell.state = cell.CellState.OBSERVED
			cell.set_selected(false) # remove o verde
			cell.update_visual()
	
	clear_all_selection()
	is_player_turn = false
	update_turn_label()
	
	await get_tree().create_timer(1.5).timeout
	move_camera_to_player()
	
	await get_tree().create_timer(2).timeout
	enemy_attack()
	
