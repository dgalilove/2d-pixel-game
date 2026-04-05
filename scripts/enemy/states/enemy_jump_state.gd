extends EnemyState


func update(delta: float) -> void:
	enemy.apply_horizontal(delta, 1.0)
	enemy.apply_gravity(delta)
	enemy.try_jump()
	enemy.try_attack()


func post_move(_delta: float) -> void:
	if machine.current_state != self:
		return

	if enemy.is_on_floor():
		if absf(enemy.intent_direction) > 0.0:
			machine.transition_to("Move")
		else:
			machine.transition_to("Idle")
		return

	var phase_frame: int = 1
	if enemy.velocity.y < -stats.jump_apex_epsilon:
		phase_frame = 0
	elif enemy.velocity.y > stats.jump_apex_epsilon:
		phase_frame = 2

	enemy.play_jump_anim_manual(phase_frame)
