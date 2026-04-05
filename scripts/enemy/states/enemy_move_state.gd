extends EnemyState


func update(delta: float) -> void:
	var brain := enemy.get_node_or_null("Brain") as EnemyBrain
	if brain == null or brain.target == null or not is_instance_valid(brain.target):
		machine.transition_to("Idle")
		return

	var dx: float = brain.target.global_position.x - enemy.global_position.x
	var dir: float = signf(dx)

	var stop_distance: float = stats.attack_range_x * 0.8
	if absf(dx) > stop_distance:
		enemy.velocity.x = move_toward(
			enemy.velocity.x,
			dir * stats.run_speed,
			stats.acceleration * delta
		)
	else:
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, stats.friction * delta)

	enemy.try_jump()
	enemy.try_attack()


func post_move(_delta: float) -> void:
	if machine.current_state != self:
		return

	var brain := enemy.get_node_or_null("Brain") as EnemyBrain
	var has_target: bool = brain != null and brain.target != null and is_instance_valid(brain.target)

	if enemy.is_on_floor():
		if not has_target:
			machine.transition_to("Idle")
		else:
			var dx: float = brain.target.global_position.x - enemy.global_position.x
			var stop_distance: float = stats.attack_range_x * 0.8
			if absf(dx) <= stop_distance:
				enemy.play_anim(stats.anim_idle)
			else:
				enemy.play_anim(stats.anim_run)
	else:
		machine.transition_to("Jump")
