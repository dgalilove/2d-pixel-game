extends EnemyState


func update(delta: float) -> void:
	var brain := enemy.get_node_or_null("Brain") as EnemyBrain
	if brain == null or brain.target == null or not is_instance_valid(brain.target):
		enemy.apply_friction(delta)
		enemy.try_jump()
		enemy.try_attack()
		return

	var dx: float = brain.target.global_position.x - enemy.global_position.x
	var stop_distance: float = stats.attack_range_x * 0.8
	var far_enough: bool = absf(dx) > stop_distance
	if far_enough or brain.get_attack_cooldown_remaining() <= 0.0:
		machine.transition_to("Move")
		return

	enemy.apply_friction(delta)
	enemy.try_jump()
	enemy.try_attack()


func post_move(_delta: float) -> void:
	if machine.current_state != self:
		return

	if absf(enemy.intent_direction) > 0.0:
		machine.transition_to("Move")
	elif not enemy.is_on_floor():
		machine.transition_to("Jump")
	else:
		enemy.play_anim(stats.anim_idle)
