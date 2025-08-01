extends BaseMachine

func _init():
	machine_type = "rice_cooker"

func _ready():
	super._ready()

func can_accept_ingredient(ingredient: Ingredient) -> bool:
	# Rice cookers can only accept raw rice
	return ingredient.type == "rice" and ingredient.state == "raw"

func get_processing_time() -> int:
	# Rice takes 3 steps to cook
	return 3

func can_process_ingredient() -> bool:
	if not current_ingredient:
		return false
	return current_ingredient.type == "rice" and current_ingredient.state == "raw"

func finish_processing():
	if is_processing:
		is_processing = false
		if current_ingredient:
			current_ingredient.finish_processing()
			# Rice is now cooked
			current_ingredient.state = "cooked"
		update_display() 