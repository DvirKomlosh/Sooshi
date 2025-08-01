class_name BaseMachine
extends Control

@export var machine_type: String = ""
@export var grid_position: Vector2 = Vector2.ZERO
@export var direction: Vector2 = Vector2.RIGHT
@export var processing_time: int = 0
@export var max_processing_time: int = 0

var current_ingredient: Ingredient = null
var is_occupied: bool = false
var is_processing: bool = false

# Visual elements
@onready var sprite: ColorRect = $Sprite
@onready var ingredient_label: Label = $IngredientLabel
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready():
	setup_visuals()
	update_display()

func setup_visuals():
	# Set up the visual representation of the machine
	if sprite:
		# Set the color based on machine type
		sprite.color = get_machine_color()

func get_machine_color() -> Color:
	match machine_type:
		"conveyor_belt":
			return Color.GRAY
		"rice_cooker":
			return Color.ORANGE
		"fish_cutter":
			return Color.BLUE
		"dish_composer":
			return Color.PURPLE
		"diner":
			return Color.GREEN
		_:
			return Color.WHITE

func update_display():
	if ingredient_label:
		if current_ingredient:
			ingredient_label.text = current_ingredient.get_display_name()
		else:
			ingredient_label.text = ""
	
	if progress_bar != null:
		if is_processing:
			progress_bar.visible = true
			progress_bar.value = float(processing_time) / float(max_processing_time) * 100.0
		else:
			progress_bar.visible = false

func add_ingredient(ingredient: Ingredient) -> bool:
	if current_ingredient == null and can_accept_ingredient(ingredient):
		current_ingredient = ingredient
		is_occupied = true
		start_processing()
		update_display()
		return true
	return false

func can_accept_ingredient(ingredient: Ingredient) -> bool:
	# Override in subclasses for specific machine logic
	return true

func start_processing():
	if current_ingredient and can_process_ingredient():
		is_processing = true
		processing_time = 0
		max_processing_time = get_processing_time()
		current_ingredient.start_processing(max_processing_time)

func can_process_ingredient() -> bool:
	if not current_ingredient:
		return false
	return current_ingredient.can_be_processed_by(machine_type)

func get_processing_time() -> int:
	# Override in subclasses for specific processing times
	return 3

func process_step(grid: Array):
	if is_processing:
		advance_processing()
	elif current_ingredient and not is_processing:
		# Try to move ingredient to next machine
		try_move_ingredient(grid)

func advance_processing():
	if is_processing:
		processing_time += 1
		if current_ingredient:
			current_ingredient.advance_processing()
		
		if processing_time >= max_processing_time:
			finish_processing()
		
		update_display()

func finish_processing():
	if is_processing:
		is_processing = false
		if current_ingredient:
			current_ingredient.finish_processing()
		update_display()

func try_move_ingredient(grid: Array):
	var target_pos = grid_position + direction
	var target_x = int(target_pos.x)
	var target_y = int(target_pos.y)
	
	# Check if target position is within grid bounds
	if target_x < 0 or target_x >= grid.size() or target_y < 0 or target_y >= grid[0].size():
		return false
	
	var target_machine = grid[target_x][target_y]
	if target_machine and target_machine.has_method("add_ingredient"):
		# Use recursive movement to handle conflicts
		var moved = try_move_recursive(grid, target_machine, [])
		if moved:
			current_ingredient = null
			is_occupied = false
			update_display()
			return true
	
	return false

func try_move_recursive(grid: Array, target_machine: BaseMachine, visited_machines: Array) -> bool:
	# Check for loops
	if visited_machines.has(target_machine):
		# Loop detected - move all items in the loop together
		move_loop_items(visited_machines)
		return true
	
	visited_machines.append(target_machine)
	
	# Try to add ingredient to target machine
	if target_machine.add_ingredient(current_ingredient):
		return true
	
	# If target is occupied, try to move its ingredient recursively
	if target_machine.current_ingredient and not target_machine.is_processing:
		var target_target_pos = target_machine.grid_position + target_machine.direction
		var target_target_x = int(target_target_pos.x)
		var target_target_y = int(target_target_pos.y)
		
		if target_target_x >= 0 and target_target_x < grid.size() and target_target_y >= 0 and target_target_y < grid[0].size():
			var target_target_machine = grid[target_target_x][target_target_y]
			if target_target_machine and target_target_machine.has_method("add_ingredient"):
				return try_move_recursive(grid, target_target_machine, visited_machines)
	
	return false

func move_loop_items(loop_machines: Array):
	# Move all items in the loop one step forward
	var loop_ingredients = []
	for machine in loop_machines:
		if machine.current_ingredient:
			loop_ingredients.append(machine.current_ingredient)
			machine.current_ingredient = null
			machine.is_occupied = false
	
	# Redistribute ingredients in the loop
	for i in range(loop_ingredients.size()):
		var next_machine = loop_machines[(i + 1) % loop_machines.size()]
		next_machine.current_ingredient = loop_ingredients[i]
		next_machine.is_occupied = true
		next_machine.update_display()

func get_output_ingredient() -> Ingredient:
	# Override in subclasses for specific output logic
	return current_ingredient

func remove_ingredient() -> Ingredient:
	var ingredient = current_ingredient
	current_ingredient = null
	is_occupied = false
	is_processing = false
	update_display()
	return ingredient

func get_machine_info() -> String:
	var info = machine_type.capitalize() + "\n"
	info += "Direction: " + str(direction) + "\n"
	if current_ingredient:
		info += "Ingredient: " + current_ingredient.get_display_name() + "\n"
		if is_processing:
			info += "Processing: " + str(processing_time) + "/" + str(max_processing_time)
	return info 
