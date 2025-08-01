# Sooshi - Sushi Factory Game

A Godot 4.3 game where you build and manage a sushi factory to serve customers.

## Game Overview

Sooshi is a grid-based factory management game where you:
- Build machines on a 15x15 grid
- Process raw ingredients into cooked dishes
- Serve customers (diners) their requested dishes
- Manage the flow of ingredients through your factory

## Game Mechanics

### Grid Layout
- **15x15 grid**: The main playing field
- **External loop**: Conveyor belts around the perimeter where ingredients spawn
- **Internal loop**: 5x5 conveyor belt loop in the center
- **8 diners**: Located inside the internal loop

### Machines

1. **Conveyor Belt** (Gray)
   - Moves ingredients in the direction it's facing
   - No processing time
   - Can accept any ingredient

2. **Rice Cooker** (Orange)
   - Processes raw rice into cooked rice
   - Processing time: 3 steps
   - Only accepts raw rice

3. **Fish Cutter** (Blue)
   - Cuts raw salmon and tuna into cut fish
   - Processing time: 2 steps
   - Only accepts raw salmon or tuna

4. **Dish Composer** (Purple)
   - Combines ingredients to create dishes
   - Processing time: 2 steps
   - Can store up to 2 ingredients
   - Creates dishes like Salmon Nigiri, Tuna Nigiri, etc.

5. **Diner** (Green)
   - Customers who request specific dishes
   - Have patience that decreases over time
   - Give points when served correctly

### Ingredients

**Raw Ingredients** (spawn on external loop):
- Nori seaweed
- Salmon fish
- Tuna fish
- Avocado
- Rice
- Tamago (egg)
- Carrot

**Processed Ingredients**:
- Cooked rice (from rice cooker)
- Cut salmon/tuna (from fish cutter)

**Composed Dishes**:
- Salmon Nigiri (cooked rice + cut salmon)
- Tuna Nigiri (cooked rice + cut tuna)
- Tamago Nigiri (cooked rice + tamago)
- Nori Roll (nori + cooked rice)

### Game Flow

1. **Step-by-step processing**: Click "Next Step" to advance the game
2. **Ingredient spawning**: New ingredients spawn on the external loop each step
3. **Machine processing**: Each machine processes or moves its ingredients
4. **Conflict resolution**: When multiple machines try to move to the same target, the system resolves conflicts using a recursive algorithm
5. **Customer satisfaction**: Diners lose patience over time and generate new requests

### How to Play

1. **Start the game**: Run the project in Godot
2. **Select a machine**: Click on a machine type from the right panel
3. **Place machines**: Click on empty grid cells to place selected machines
4. **Set directions**: Machines face in the direction they were placed (default: right)
5. **Process steps**: Click "Next Step" to advance the simulation
6. **Serve customers**: Build efficient production lines to serve diners quickly
7. **Score points**: Satisfied customers give points based on dish value

### Tips

- **Plan your layout**: Think about the flow of ingredients from external loop to diners
- **Use conveyor belts efficiently**: They're the backbone of your factory
- **Process ingredients**: Raw ingredients need to be processed before composition
- **Serve quickly**: Diners lose patience over time
- **Experiment**: Try different machine combinations and layouts

### Controls

- **Left Click**: Place selected machine on grid
- **Next Step Button**: Advance the game simulation
- **Machine Buttons**: Select machine type to place

### Scoring

- **Salmon Nigiri**: 5 points
- **Tuna Nigiri**: 5 points
- **Tamago Nigiri**: 5 points
- **Nori Roll**: 3 points

The goal is to efficiently process ingredients and serve customers to maximize your score!

## Technical Details

- Built with Godot 4.3
- Uses GDScript for all game logic
- Grid-based state management
- Recursive conflict resolution for machine movement
- Step-by-step simulation system

Enjoy building your sushi factory! 