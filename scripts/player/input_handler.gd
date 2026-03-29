class_name InputHandler
extends Node

var direction: float = 0.0
var direction_magnitude: float = 0.0
var jump_just_pressed: bool = false
var dash_just_pressed: bool = false
var attack_just_pressed: bool = false


func _ready() -> void:
	_ensure_input_actions()


func poll() -> void:
	direction = Input.get_axis("move_left", "move_right")
	direction_magnitude = absf(direction)
	jump_just_pressed = Input.is_action_just_pressed("jump")
	dash_just_pressed = Input.is_action_just_pressed("dash")
	attack_just_pressed = Input.is_action_just_pressed("attack")


func _ensure_input_actions() -> void:
	_add_action_with_deadzone("move_left", 0.2)
	_add_action_with_deadzone("move_right", 0.2)

	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_button("jump", JOY_BUTTON_A)
	_add_button("attack", JOY_BUTTON_X)
	_add_button("dash", JOY_BUTTON_B)


func _add_action_with_deadzone(action_name: StringName, deadzone: float) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, deadzone)


func _add_button(action_name: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func _add_axis(action_name: StringName, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)
