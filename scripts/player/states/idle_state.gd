extends PlayerState


func update(delta: float) -> void:
	player.apply_friction(delta)
	player.try_jump()
	player.try_dash()
	player.try_attack()


func post_move(_delta: float) -> void:
	if machine.current_state != self:
		return

	if absf(input.direction) > 0.0:
		machine.transition_to("Move")
	elif not player.is_on_floor():
		machine.transition_to("Fall")
	else:
		player.play_anim(stats.anim_idle)
