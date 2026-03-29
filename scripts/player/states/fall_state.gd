extends PlayerState


func update(delta: float) -> void:
	player.apply_horizontal(delta, 1.0)
	player.apply_gravity(delta)
	player.try_jump()
	player.try_dash()
	player.try_attack()


func post_move(_delta: float) -> void:
	if machine.current_state != self:
		return

	if player.is_on_floor():
		if absf(input.direction) > 0.0:
			machine.transition_to("Move")
		else:
			machine.transition_to("Idle")
		return

	if player.velocity.y > stats.jump_apex_epsilon:
		player.play_anim(stats.anim_jump_fall)
	else:
		player.play_anim(stats.anim_jump_middle)
