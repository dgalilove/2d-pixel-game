class_name EnemyStateMachine
extends Node

@export var initial_state: NodePath

var current_state: EnemyState
var states: Dictionary = {}

var enemy: CharacterBody2D
var stats: EnemyStats


func setup(p_enemy: CharacterBody2D, p_stats: EnemyStats) -> void:
	enemy = p_enemy
	stats = p_stats

	for child in get_children():
		if child is EnemyState:
			states[child.name] = child
			child.enemy = enemy
			child.stats = stats
			child.machine = self

	if initial_state:
		current_state = get_node(initial_state) as EnemyState
	else:
		current_state = get_child(0) as EnemyState

	if current_state:
		current_state.enter()


func transition_to(state_name: StringName) -> void:
	if not states.has(state_name):
		push_warning("EnemyStateMachine: state '%s' not found" % state_name)
		return

	var next_state: EnemyState = states[state_name]
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
