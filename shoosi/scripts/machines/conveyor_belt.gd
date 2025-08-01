extends BaseMachine

func _init():
	machine_type = "conveyor_belt"

func _ready():
	super._ready()

func can_accept_ingredient(ingredient: Ingredient) -> bool:
	# Conveyor belts can accept any ingredient
	return true

func get_processing_time() -> int:
	# Conveyor belts don't process, they just move
	return 0

func can_process_ingredient() -> bool:
	# Conveyor belts don't process ingredients
	return false

func process_step(grid: Array):
	# Conveyor belts only move ingredients, they don't process them
	if current_ingredient and not is_processing:
		try_move_ingredient(grid) 