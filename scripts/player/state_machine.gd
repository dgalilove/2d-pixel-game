class_name StateMachine
extends Node

@export var initial_state: NodePath

var current_state: PlayerState
var states: Dictionary = {}

var player: CharacterBody2D
var input: InputHandler
var stats: PlayerStats


func setup(p_player: CharacterBody2D, p_input: InputHandler, p_stats: PlayerStats) -> void:
	player = p_player
	input = p_input
	stats = p_stats

	for child in get_children():
		if child is PlayerState:
			states[child.name] = child
			child.player = player
			child.input = input
			child.stats = stats
			child.machine = self

	if initial_state:
		current_state = get_node(initial_state) as PlayerState
	else:
		current_state = get_child(0) as PlayerState

	if current_state:
		current_state.enter()


func transition_to(state_name: StringName) -> void:
	if not states.has(state_name):
		push_warning("StateMachine: state '%s' not found" % state_name)
		return

	var next_state: PlayerState = states[state_name]
	if next_state == current_state:
		return

	current_state.exit()
	current_state = next_state
	current_state.enter()


func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func post_move(delta: float) -> void:
	if current_state:
		current_state.post_move(delta)
