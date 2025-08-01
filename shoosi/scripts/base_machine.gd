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
var is_moving: bool = false
var animation_tween: Tween = null
var visited_tag: int = 0
var processed_tag: int = 0

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
	
	# Update sprite color to show ingredient
	if sprite and current_ingredient:
		sprite.color = get_ingredient_color(current_ingredient)
	elif sprite:
		sprite.color = get_machine_color()

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
		# Use recursive processing to handle conflicts
		try_process_recursive(grid, [])

func try_process_recursive(grid: Array, visited_machines: Array):
	# Check for loops using visited tag
	if processed_tag == get_current_step_tag() or not current_ingredient:
		processed_tag = get_current_step_tag()
		return true
	
	if visited_tag == get_current_step_tag():
		# Loop detected - find the loop machines efficiently
		var loop_machines = get_loop_machines(visited_machines)
		move_loop_items(loop_machines)
		return true
	
	visited_tag = get_current_step_tag()
	visited_machines.append(self)
	
	# Try to move ingredient to next machine
	var target_pos = grid_position + direction
	var target_x = int(target_pos.x)
	var target_y = int(target_pos.y)
	
	# Check if target position is within grid bounds
	if target_x < 0 or target_x >= grid.size() or target_y < 0 or target_y >= grid[0].size():
		return true
	
	var target_machine = grid[target_x][target_y]
	if target_machine and target_machine.has_method("add_ingredient"):
		target_machine.try_process_recursive(grid, visited_machines)
		if processed_tag == get_current_step_tag():
			return true
		if target_machine.add_ingredient(current_ingredient):
			current_ingredient = null
			is_occupied = false
			# Start animation to target machine
			animate_ingredient_to_target(target_machine)
			processed_tag = get_current_step_tag()
			return true
	
	processed_tag = get_current_step_tag()
	return true

func advance_processing():
	if is_processing:
		processing_time += 1
		if current_ingredient:
			current_ingredient.advance_processing()
		
		if processing_time >= max_processing_time:
			finish_processing()
		

func finish_processing():
	if is_processing:
		is_processing = false
		if current_ingredient:
			current_ingredient.finish_processing()



func get_loop_machines(visited_machines: Array) -> Array:
	# Find the current machine's position in the visited list
	var current_index = visited_machines.find(self)
	if current_index == -1:
		return []
	
	# Return the machines from the current position to the end (the loop)
	return visited_machines.slice(current_index)

func move_loop_items(loop_machines: Array):
	# Move all items in the loop one step forward
	var loop_ingredients = []
	for machine in loop_machines:
		machine.processed_tag = get_current_step_tag()
		if machine.current_ingredient:
			loop_ingredients.append(machine.current_ingredient)
			machine.current_ingredient = null
			machine.is_occupied = false
	
	# Redistribute ingredients in the loop
	for i in range(loop_ingredients.size()):
		var next_machine = loop_machines[(i + 1) % loop_machines.size()]
		next_machine.current_ingredient = loop_ingredients[i]
		next_machine.is_occupied = true

func get_current_step_tag() -> int:
	# Get the current step tag from the main game
	var main_game = get_tree().current_scene.get_node("MainGame")
	if main_game:
		return main_game.step_count
	return 0

func get_output_ingredient() -> Ingredient:
	# Override in subclasses for specific output logic
	return current_ingredient

func remove_ingredient() -> Ingredient:
	var ingredient = current_ingredient
	current_ingredient = null
	is_occupied = false
	is_processing = false
	return ingredient

func get_machine_info() -> String:
	var info = machine_type.capitalize() + "\n"
	info += "Direction: " + str(direction) + "\n"
	if current_ingredient:
		info += "Ingredient: " + current_ingredient.get_display_name() + "\n"
		if is_processing:
			info += "Processing: " + str(processing_time) + "/" + str(max_processing_time)
	return info

func animate_ingredient_to_target(target_machine: BaseMachine):
	if not current_ingredient or is_moving:
		return
	
	is_moving = true
	
	# Create a visual representation of the ingredient for animation
	var ingredient_sprite = ColorRect.new()
	ingredient_sprite.color = get_ingredient_color(current_ingredient)
	ingredient_sprite.size = Vector2(20, 20)
	
	# Store reference to target machine and sprite
	ingredient_sprite.set_meta("target_machine", target_machine)
	ingredient_sprite.set_meta("source_machine", self)
	
	# Add to the scene tree
	get_tree().current_scene.add_child(ingredient_sprite)
	
	# Calculate positions
	var start_global_pos = global_position + Vector2(10, 10)  # Center of current machine
	var target_global_pos = target_machine.global_position + Vector2(10, 10)  # Center of target machine
	
	# Set initial position
	ingredient_sprite.global_position = start_global_pos
	
	# Create tween for smooth movement with easing
	animation_tween = create_tween()
	animation_tween.set_ease(Tween.EASE_IN_OUT)
	animation_tween.set_trans(Tween.TRANS_QUAD)
	animation_tween.tween_property(ingredient_sprite, "global_position", target_global_pos, 0.5)
	animation_tween.tween_callback(finish_ingredient_movement)

func get_ingredient_color(ingredient: Ingredient) -> Color:
	match ingredient.type:
		"rice":
			return Color.WHITE
		"salmon":
			return Color(1, 0.5, 0.5, 1)  # Light red
		"tuna":
			return Color(0.5, 0.5, 1, 1)  # Light blue
		"nori":
			return Color(0.2, 0.4, 0.2, 1)  # Dark green
		"avocado":
			return Color(0.2, 0.8, 0.2, 1)  # Green
		"tamago":
			return Color(1, 1, 0.5, 1)  # Light yellow
		"carrot":
			return Color(1, 0.6, 0.2, 1)  # Orange
		"salmon_nigiri", "tuna_nigiri", "tamago_nigiri":
			return Color(1, 1, 0.8, 1)  # Light cream
		"nori_roll":
			return Color(0.3, 0.6, 0.3, 1)  # Medium green
		_:
			return Color.GRAY

func finish_ingredient_movement():
	# Find the animated sprite that just finished
	var animated_sprites = get_tree().current_scene.get_children()
	var ingredient_sprite = null
	var target_machine = null
	var source_machine = null
	
	for sprite in animated_sprites:
		if sprite is ColorRect and sprite.has_meta("source_machine") and sprite.get_meta("source_machine") == self:
			ingredient_sprite = sprite
			target_machine = sprite.get_meta("target_machine")
			source_machine = sprite.get_meta("source_machine")
			break
	
	if not ingredient_sprite or not target_machine:
		return
	
	# Remove the animated sprite
	ingredient_sprite.queue_free()
	
	# Transfer ingredient to target machine
	var ingredient = current_ingredient
	current_ingredient = null
	is_occupied = false
	is_moving = false
	
	# Add to target machine
	if target_machine.add_ingredient(ingredient):
		# Successfully added to target
		pass
	else:
		# Failed to add - this shouldn't happen with our logic, but just in case
		print("Failed to add ingredient to target machine")
