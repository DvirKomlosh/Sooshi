extends BaseMachine

func _init():
	machine_type = "fish_cutter"

func _ready():
	super._ready()

func can_accept_ingredient(ingredient: Ingredient) -> bool:
	# Fish cutters can only accept raw salmon or tuna
	return (ingredient.type == "salmon" or ingredient.type == "tuna") and ingredient.state == "raw"

func get_processing_time() -> int:
	# Fish cutting takes 2 steps
	return 2

func can_process_ingredient() -> bool:
	if not current_ingredient:
		return false
	return (current_ingredient.type == "salmon" or current_ingredient.type == "tuna") and current_ingredient.state == "raw"

func finish_processing():
	if is_processing:
		is_processing = false
		if current_ingredient:
			current_ingredient.finish_processing()
			# Fish is now cut
			current_ingredient.state = "cut"
		update_display() 