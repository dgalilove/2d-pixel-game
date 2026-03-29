extends PlayerState


func update(delta: float) -> void:
	player.apply_horizontal(delta, 1.0)
	player.try_jump()
	player.try_dash()
	player.try_attack()


func post_move(_delta: float) -> void:
	if machine.current_state != self:
		return

	if player.is_on_floor():
		if absf(input.direction) == 0.0:
			machine.transition_to("Idle")
		elif absf(player.velocity.x) > stats.run_threshold:
			player.play_anim(stats.anim_run)
		else:
			player.play_anim(stats.anim_walk)
	else:
		machine.transition_to("Fall")
