extends BaseMachine

var requested_dish: String = ""
var patience: int = 10
var max_patience: int = 10
var is_satisfied: bool = false

@onready var request_label: Label = $RequestLabel

func _init():
	machine_type = "diner"

func _ready():
	super._ready()
	generate_request()

func generate_request():
	var possible_dishes = ["salmon_nigiri", "tuna_nigiri", "tamago_nigiri", "nori_roll"]
	requested_dish = possible_dishes[randi() % possible_dishes.size()]
	patience = max_patience
	is_satisfied = false
	update_display()

func can_accept_ingredient(ingredient: Ingredient) -> bool:
	# Diners can only accept composed dishes that match their request
	return ingredient.is_composed() and ingredient.type == requested_dish

func add_ingredient(ingredient: Ingredient) -> bool:
	if can_accept_ingredient(ingredient):
		current_ingredient = ingredient
		is_occupied = true
		is_satisfied = true
		update_display()
		return true
	return false

func update_state():
	# Called by the main game to update diner state
	if not is_satisfied:
		patience -= 1
		if patience <= 0:
			# Diner leaves unsatisfied
			generate_request()
		update_display()

func update_display():
	super.update_display()
	
	if request_label:
		if is_satisfied:
			request_label.text = "Satisfied!"
			request_label.modulate = Color.GREEN
		else:
			request_label.text = "Wants: " + requested_dish.replace("_", " ").capitalize()
			request_label.modulate = Color.RED

func get_machine_info() -> String:
	var info = machine_type.capitalize() + "\n"
	info += "Request: " + requested_dish.replace("_", " ").capitalize() + "\n"
	info += "Patience: " + str(patience) + "/" + str(max_patience) + "\n"
	
	if current_ingredient:
		info += "Served: " + current_ingredient.get_display_name()
	elif is_satisfied:
		info += "Status: Satisfied"
	else:
		info += "Status: Waiting"
	
	return info

func get_score_value() -> int:
	if is_satisfied and current_ingredient:
		return current_ingredient.get_dish_value()
	return 0 