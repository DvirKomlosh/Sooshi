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
	# Top row (left to right)
	for i in range(GRID_SIZE - 1):
		place_machine_at(i, 0, "conveyor_belt", Vector2.RIGHT)
	
	# Right column (top to bottom, excluding top corner)
	for i in range(GRID_SIZE - 1):
		place_machine_at(GRID_SIZE - 1, i, "conveyor_belt", Vector2.DOWN)
	
	# Bottom row (right to left, excluding right corner)
	for i in range(GRID_SIZE - 1):
		place_machine_at(GRID_SIZE - 1 - i, GRID_SIZE - 1, "conveyor_belt", Vector2.LEFT)
	
	# Left column (bottom to top, excluding bottom corner)
	for i in range(GRID_SIZE - 1):
		place_machine_at(0, GRID_SIZE - 1 - i, "conveyor_belt", Vector2.UP)
	

func spawn_internal_conveyors():
	# Spawn conveyor belts on the inner loop (5x5 grid perimeter)
	# Top row of inner loop (left to right)
	for i in range(INNER_LOOP_SIZE - 1):
		place_machine_at(INNER_LOOP_START + i, INNER_LOOP_START, "conveyor_belt", Vector2.RIGHT)
	
	# Right column of inner loop (top to bottom, excluding top corner)
	for i in range(INNER_LOOP_SIZE - 1):
		place_machine_at(INNER_LOOP_END, INNER_LOOP_START + i, "conveyor_belt", Vector2.DOWN)
	
	# Bottom row of inner loop (right to left, excluding right corner)
	for i in range(INNER_LOOP_SIZE - 1):
		place_machine_at(INNER_LOOP_END - i, INNER_LOOP_END, "conveyor_belt", Vector2.LEFT)
	
	# Left column of inner loop (bottom to top, excluding bottom corner)
	for i in range(INNER_LOOP_SIZE - 1):
		place_machine_at(INNER_LOOP_START, INNER_LOOP_END - i, "conveyor_belt", Vector2.UP)


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
	var ingredient_sequence = ["rice", "salmon", "tuna", "nori", "avocado", "tamago", "carrot"]
	var spawn_position = Vector2(0, 0)  # Top-left corner
	
	# Get the ingredient for this step based on step count
	var ingredient_index = step_count % ingredient_sequence.size()
	var ingredient_type = ingredient_sequence[ingredient_index]
	
	# Spawn the ingredient at the top-left corner
	var machine = grid[spawn_position.x][spawn_position.y]
	if machine and machine.has_method("add_ingredient"):
		machine.add_ingredient(create_ingredient(ingredient_type))



func process_all_machines():
	# Create a copy of the grid to avoid conflicts during processing
	var processing_order = get_machine_processing_order()
	
	# Process machines with a small delay to allow animations to complete
	for i in range(processing_order.size()):
		var machine = processing_order[i]
		if machine and machine.has_method("process_step"):
			machine.process_step(grid)
		
		# Add a small delay between machine processing to allow animations
		if i < processing_order.size() - 1:
			await get_tree().create_timer(0.1).timeout

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
