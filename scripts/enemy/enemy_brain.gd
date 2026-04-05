extends Node
class_name EnemyBrain

@export var vision_range: Area2D
@export var target_path: NodePath

var target: CharacterBody2D

var _attack_cd: float = 0.0
var _jump_cd: float = 0.0


func _ready() -> void:
	if vision_range:
		vision_range.body_entered.connect(_on_vision_body_entered)
		vision_range.body_exited.connect(_on_vision_body_exited)
		call_deferred("_sync_vision_overlaps")

	if not target_path.is_empty():
		var n := get_node_or_null(target_path)
		if n is CharacterBody2D:
			target = n as CharacterBody2D


func _sync_vision_overlaps() -> void:
	if vision_range == null:
		return
	for body in vision_range.get_overlapping_bodies():
		_on_vision_body_entered(body as Node2D)


func _on_vision_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == &"Player":
		target = body as CharacterBody2D


func _on_vision_body_exited(body: Node2D) -> void:
	if body == target:
		target = null


func set_attack_cooldown(seconds: float) -> void:
	_attack_cd = maxf(0.0, seconds)


func get_attack_cooldown_remaining() -> float:
	return _attack_cd


func is_target_in_attack_range() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var parent := get_parent() as Node2D
	if parent == null:
		return false
	var es: Variant = parent.get("stats")
	if es == null or not (es is EnemyStats):
		return false
	var st: EnemyStats = es
	var rel: Vector2 = target.global_position - parent.global_position
	return absf(rel.x) <= st.attack_range_x and absf(rel.y) <= st.attack_range_y


func tick(delta: float) -> void:
	var enemy: Node = get_parent()
	if enemy == null:
		return

	var es: Variant = enemy.get("stats")
	if es == null or not (es is EnemyStats):
		enemy.intent_direction = 0.0
		return
	var stats: EnemyStats = es

	if target == null or not is_instance_valid(target):
		enemy.intent_direction = 0.0
		return

	_attack_cd = maxf(0.0, _attack_cd - delta)
	_jump_cd = maxf(0.0, _jump_cd - delta)

	var to_player: Vector2 = target.global_position - enemy.global_position
	var dx: float = to_player.x
	var dy: float = to_player.y

	var stop_distance: float = stats.attack_range_x * 0.8
	if absf(dx) > stop_distance:
		enemy.intent_direction = signf(dx)
	else:
		enemy.intent_direction = 0.0

	var sm = enemy.get("state_machine")
	var in_attack: bool = (
		sm != null
		and sm.current_state != null
		and sm.current_state.name == &"Attack"
	)

	if not in_attack:
		var in_melee: bool = absf(dx) <= stats.attack_range_x and absf(dy) <= stats.attack_range_y
		if in_melee and _attack_cd <= 0.0:
			enemy.intent_attack = true

	if stats.jump_if_player_above and enemy.is_on_floor() and _jump_cd <= 0.0:
		if dy < -stats.jump_height_threshold:
			enemy.intent_jump = true
			_jump_cd = stats.jump_cooldown
