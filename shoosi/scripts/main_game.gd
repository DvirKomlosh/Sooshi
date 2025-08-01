extends Control

class_name MainGame

signal step_completed

# Game constants
const GRID_SIZE = 15
const INNER_LOOP_SIZE = 5
const INNER_LOOP_START = 5
const INNER_LOOP_END = 9

# Game state
var grid: Array[Array] = []
var selected_machine_type: String = ""
var score: int = 0
var step_count: int = 0

# UI references
@onready var grid_container: GridContainer = $GridContainer
@onready var score_label: Label = $UI/TopPanel/ScoreLabel
@onready var step_button: Button = $UI/TopPanel/StepButton

# Machine buttons
@onready var conveyor_button: Button = $UI/MachinePanel/MachineList/ConveyorButton
@onready var rice_cooker_button: Button = $UI/MachinePanel/MachineList/RiceCookerButton
@onready var fish_cutter_button: Button = $UI/MachinePanel/MachineList/FishCutterButton
@onready var dish_composer_button: Button = $UI/MachinePanel/MachineList/DishComposerButton

func _ready():
	initialize_grid()
	setup_ui_connections()
	spawn_external_conveyors()
	spawn_internal_conveyors()
	spawn_diners()

func initialize_grid():
	# Initialize 15x15 grid
	grid = []
	for x in range(GRID_SIZE):
		grid.append([])
		for y in range(GRID_SIZE):
			grid[x].append(null)
	
	# Create empty placeholder cells for the grid
	create_empty_grid_cells()

func setup_ui_connections():
	step_button.pressed.connect(_on_step_button_pressed)
	conveyor_button.pressed.connect(_on_conveyor_button_pressed)
	rice_cooker_button.pressed.connect(_on_rice_cooker_button_pressed)
	fish_cutter_button.pressed.connect(_on_fish_cutter_button_pressed)
	dish_composer_button.pressed.connect(_on_dish_composer_button_pressed)

func spawn_external_conveyors():
	# Spawn conveyor belts on the outer loop (15x15 grid perimeter)
	for i in range(GRID_SIZE):
		# Top row
		place_machine_at(i, 0, "conveyor_belt", Vector2.RIGHT)
		# Bottom row
		place_machine_at(i, GRID_SIZE - 1, "conveyor_belt", Vector2.LEFT)
		# Left column
		place_machine_at(0, i, "conveyor_belt", Vector2.DOWN)
		# Right column
		place_machine_at(GRID_SIZE - 1, i, "conveyor_belt", Vector2.UP)

func spawn_internal_conveyors():
	# Spawn conveyor belts on the inner loop (5x5 grid perimeter)
	for i in range(INNER_LOOP_SIZE):
		# Top row of inner loop
		place_machine_at(INNER_LOOP_START + i, INNER_LOOP_START, "conveyor_belt", Vector2.RIGHT)
		# Bottom row of inner loop
		place_machine_at(INNER_LOOP_START + i, INNER_LOOP_END, "conveyor_belt", Vector2.LEFT)
		# Left column of inner loop
		place_machine_at(INNER_LOOP_START, INNER_LOOP_START + i, "conveyor_belt", Vector2.DOWN)
		# Right column of inner loop
		place_machine_at(INNER_LOOP_END, INNER_LOOP_START + i, "conveyor_belt", Vector2.UP)

func spawn_diners():
	# Spawn 8 diners on the inner side of the inner loop
	var diner_positions = [
		Vector2(INNER_LOOP_START + 1, INNER_LOOP_START + 1),
		Vector2(INNER_LOOP_START + 2, INNER_LOOP_START + 1),
		Vector2(INNER_LOOP_START + 3, INNER_LOOP_START + 1),
		Vector2(INNER_LOOP_START + 1, INNER_LOOP_START + 2),
		Vector2(INNER_LOOP_START + 3, INNER_LOOP_START + 2),
		Vector2(INNER_LOOP_START + 1, INNER_LOOP_START + 3),
		Vector2(INNER_LOOP_START + 2, INNER_LOOP_START + 3),
		Vector2(INNER_LOOP_START + 3, INNER_LOOP_START + 3)
	]
	
	for pos in diner_positions:
		place_machine_at(pos.x, pos.y, "diner", Vector2.ZERO)



func create_empty_grid_cells():
	# Create empty placeholder cells for the 15x15 grid
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var placeholder = ColorRect.new()
			placeholder.color = Color(0.2, 0.2, 0.2, 0.3)
			placeholder.custom_minimum_size = Vector2(40, 40)
			grid_container.add_child(placeholder)

func place_machine_at(x: int, y: int, machine_type: String, direction: Vector2):
	var machine_scene = load("res://scenes/machines/" + machine_type + ".tscn")
	var machine = machine_scene.instantiate()
	
	# Set the machine's position in the grid
	machine.grid_position = Vector2(x, y)
	machine.direction = direction
	grid[x][y] = machine
	
	# Replace the placeholder at the correct position
	var grid_pos = y * GRID_SIZE + x
	var placeholder = grid_container.get_child(grid_pos)
	if placeholder:
		grid_container.remove_child(placeholder)
		placeholder.queue_free()
	
	grid_container.add_child(machine)
	grid_container.move_child(machine, grid_pos)

func _on_step_button_pressed():
	execute_game_step()

func execute_game_step():
	step_count += 1
	
	# 1. Spawn new ingredients on external loop
	spawn_ingredients_on_external_loop()
	
	# 2. Process all machines
	process_all_machines()
	
	# 3. Update diners
	update_diners()
	
	# 4. Update UI
	update_ui()
	
	step_completed.emit()

func spawn_ingredients_on_external_loop():
	var ingredients = ["nori", "salmon", "tuna", "avocado", "rice", "tamago", "carrot"]
	var external_positions = get_external_loop_positions()
	
	# Spawn ingredients randomly on external loop
	for i in range(3):  # Spawn 3 ingredients per step
		var random_pos = external_positions[randi() % external_positions.size()]
		var random_ingredient = ingredients[randi() % ingredients.size()]
		
		var machine = grid[random_pos.x][random_pos.y]
		if machine and machine.has_method("add_ingredient"):
			machine.add_ingredient(create_ingredient(random_ingredient))

func get_external_loop_positions() -> Array:
	var positions = []
	
	# Top and bottom rows
	for x in range(GRID_SIZE):
		positions.append(Vector2(x, 0))
		positions.append(Vector2(x, GRID_SIZE - 1))
	
	# Left and right columns (excluding corners)
	for y in range(1, GRID_SIZE - 1):
		positions.append(Vector2(0, y))
		positions.append(Vector2(GRID_SIZE - 1, y))
	
	return positions

func process_all_machines():
	# Create a copy of the grid to avoid conflicts during processing
	var processing_order = get_machine_processing_order()
	
	for machine in processing_order:
		if machine and machine.has_method("process_step"):
			machine.process_step(grid)

func get_machine_processing_order() -> Array:
	var machines = []
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] != null:
				machines.append(grid[x][y])
	
	# Sort machines by a deterministic order (e.g., by position)
	machines.sort_custom(func(a, b): 
		if a.grid_position.y != b.grid_position.y:
			return a.grid_position.y < b.grid_position.y
		return a.grid_position.x < b.grid_position.x)
	
	return machines

func update_diners():
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var machine = grid[x][y]
			if machine and machine.machine_type == "diner":
				machine.update_state()
				# Add score for satisfied diners
				if machine.has_method("get_score_value"):
					score += machine.get_score_value()

func update_ui():
	score_label.text = "Score: " + str(score) + " | Step: " + str(step_count)

func create_ingredient(type: String) -> Ingredient:
	var ingredient = Ingredient.new()
	ingredient.type = type
	ingredient.state = "raw"
	return ingredient

# UI button handlers
func _on_conveyor_button_pressed():
	selected_machine_type = "conveyor_belt"

func _on_rice_cooker_button_pressed():
	selected_machine_type = "rice_cooker"

func _on_fish_cutter_button_pressed():
	selected_machine_type = "fish_cutter"

func _on_dish_composer_button_pressed():
	selected_machine_type = "dish_composer"

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_machine_type != "":
			handle_grid_click(event.position)

func handle_grid_click(mouse_pos: Vector2):
	var grid_pos = get_grid_position_from_mouse(mouse_pos)
	if grid_pos != Vector2(-1, -1):
		var x = int(grid_pos.x)
		var y = int(grid_pos.y)
		
		# Check if position is valid and empty
		if x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE:
			if grid[x][y] == null:
				place_machine_at(x, y, selected_machine_type, Vector2.RIGHT)
				selected_machine_type = ""

func get_grid_position_from_mouse(mouse_pos: Vector2) -> Vector2:
	var grid_rect = grid_container.get_global_rect()
	if grid_rect.has_point(mouse_pos):
		var local_pos = mouse_pos - grid_rect.position
		var cell_size = grid_rect.size / Vector2(GRID_SIZE, GRID_SIZE)
		var grid_x = int(local_pos.x / cell_size.x)
		var grid_y = int(local_pos.y / cell_size.y)
		return Vector2(grid_x, grid_y)
	return Vector2(-1, -1) 
