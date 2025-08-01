class_name Ingredient
extends Resource

@export var type: String = ""
@export var state: String = "raw"  # raw, cooked, cut, composed
@export var processing_time: int = 0
@export var max_processing_time: int = 0

# Composed ingredients can contain multiple ingredients
@export var sub_ingredients: Array[Ingredient] = []

func _init(ingredient_type: String = "", ingredient_state: String = "raw"):
	type = ingredient_type
	state = ingredient_state

func is_raw() -> bool:
	return state == "raw"

func is_cooked() -> bool:
	return state == "cooked"

func is_cut() -> bool:
	return state == "cut"

func is_composed() -> bool:
	return state == "composed"

func get_display_name() -> String:
	var display_name = type.capitalize()
	if state != "raw":
		display_name = state.capitalize() + " " + display_name
	return display_name

func can_be_processed_by(machine_type: String) -> bool:
	match machine_type:
		"rice_cooker":
			return type == "rice" and state == "raw"
		"fish_cutter":
			return (type == "salmon" or type == "tuna") and state == "raw"
		"dish_composer":
			return is_ready_for_composition()
		_:
			return false

func is_ready_for_composition() -> bool:
	# Check if this ingredient can be used in dish composition
	match type:
		"rice":
			return state == "cooked"
		"salmon", "tuna":
			return state == "cut"
		"nori", "avocado", "tamago", "carrot":
			return state == "raw"
		_:
			return false

func get_composition_value() -> int:
	# Return a value representing how valuable this ingredient is for composition
	match type:
		"rice":
			return 2 if state == "cooked" else 1
		"salmon", "tuna":
			return 3 if state == "cut" else 1
		"nori":
			return 2
		"avocado":
			return 1
		"tamago":
			return 2
		"carrot":
			return 1
		_:
			return 1

func start_processing(processing_duration: int):
	processing_time = 0
	max_processing_time = processing_duration

func is_processing() -> bool:
	return processing_time < max_processing_time

func advance_processing():
	if is_processing():
		processing_time += 1

func finish_processing():
	if is_processing():
		processing_time = max_processing_time
		complete_processing()

func complete_processing():
	match type:
		"rice":
			if state == "raw":
				state = "cooked"
		"salmon", "tuna":
			if state == "raw":
				state = "cut"
		_:
			pass

func can_combine_with(other: Ingredient) -> bool:
	# Check if this ingredient can be combined with another for dish composition
	if type == "rice" and state == "cooked":
		if other.type == "salmon" and other.state == "cut":
			return true
		if other.type == "tuna" and other.state == "cut":
			return true
		if other.type == "tamago" and other.state == "raw":
			return true
	
	if type == "nori" and state == "raw":
		if other.type == "rice" and other.state == "cooked":
			return true
	
	return false

func combine_with(other: Ingredient) -> Ingredient:
	# Create a composed ingredient from two ingredients
	var composed = Ingredient.new()
	composed.state = "composed"
	composed.sub_ingredients = [self, other]
	
	# Determine the dish type based on ingredients
	if type == "rice" and state == "cooked":
		if other.type == "salmon" and other.state == "cut":
			composed.type = "salmon_nigiri"
		elif other.type == "tuna" and other.state == "cut":
			composed.type = "tuna_nigiri"
		elif other.type == "tamago" and other.state == "raw":
			composed.type = "tamago_nigiri"
	
	elif type == "nori" and state == "raw":
		if other.type == "rice" and other.state == "cooked":
			composed.type = "nori_roll"
	
	return composed

func get_dish_value() -> int:
	# Return the value of this dish for scoring
	match type:
		"salmon_nigiri", "tuna_nigiri", "tamago_nigiri":
			return 5
		"nori_roll":
			return 3
		_:
			return 1 