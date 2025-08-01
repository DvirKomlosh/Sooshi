extends BaseMachine

var stored_ingredients: Array[Ingredient] = []
var max_stored_ingredients: int = 2

func _init():
	machine_type = "dish_composer"

func _ready():
	super._ready()

func can_accept_ingredient(ingredient: Ingredient) -> bool:
	# Dish composers can accept any ingredient that's ready for composition
	if stored_ingredients.size() >= max_stored_ingredients:
		return false
	
	return ingredient.is_ready_for_composition()

func add_ingredient(ingredient: Ingredient) -> bool:
	if can_accept_ingredient(ingredient):
		stored_ingredients.append(ingredient)
		is_occupied = true
		
		# Check if we can compose a dish
		if stored_ingredients.size() >= 2:
			start_processing()
		
		update_display()
		return true
	return false

func get_processing_time() -> int:
	# Dish composition takes 2 steps
	return 2

func can_process_ingredient() -> bool:
	# Can process if we have at least 2 ingredients that can be combined
	if stored_ingredients.size() < 2:
		return false
	
	# Check if any two ingredients can be combined
	for i in range(stored_ingredients.size()):
		for j in range(i + 1, stored_ingredients.size()):
			if stored_ingredients[i].can_combine_with(stored_ingredients[j]):
				return true
	
	return false

func finish_processing():
	if is_processing:
		is_processing = false
		
		# Find ingredients that can be combined
		var combined = false
		for i in range(stored_ingredients.size()):
			for j in range(i + 1, stored_ingredients.size()):
				if stored_ingredients[i].can_combine_with(stored_ingredients[j]):
					# Create composed dish
					current_ingredient = stored_ingredients[i].combine_with(stored_ingredients[j])
					
					# Remove the used ingredients
					stored_ingredients.remove_at(j)
					stored_ingredients.remove_at(i)
					
					combined = true
					break
			if combined:
				break
		
		update_display()

func update_display():
	if ingredient_label:
		if current_ingredient:
			ingredient_label.text = current_ingredient.get_display_name()
		elif stored_ingredients.size() > 0:
			var display_text = ""
			for ingredient in stored_ingredients:
				display_text += ingredient.get_display_name() + " "
			ingredient_label.text = display_text.strip_edges()
		else:
			ingredient_label.text = ""
	
	if progress_bar:
		if is_processing:
			progress_bar.visible = true
			progress_bar.value = float(processing_time) / float(max_processing_time) * 100.0
		else:
			progress_bar.visible = false

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
	info += "Stored: " + str(stored_ingredients.size()) + "/" + str(max_stored_ingredients) + "\n"
	
	if current_ingredient:
		info += "Dish: " + current_ingredient.get_display_name() + "\n"
		if is_processing:
			info += "Processing: " + str(processing_time) + "/" + str(max_processing_time)
	elif stored_ingredients.size() > 0:
		info += "Ingredients: "
		for ingredient in stored_ingredients:
			info += ingredient.get_display_name() + " "
	
	return info 