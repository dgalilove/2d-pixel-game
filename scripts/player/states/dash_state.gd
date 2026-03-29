extends PlayerState


func enter() -> void:
	player.begin_dash()


func exit() -> void:
	player.end_dash_phase()


func update(delta: float) -> void:
	player.dash_time = maxf(0.0, player.dash_time - delta)
	player.dash_ghost_time = maxf(0.0, player.dash_ghost_time - delta)

	if stats.dash_ghost_interval > 0.0 and player.dash_ghost_time <= 0.0:
		player.dash_ghost_time = stats.dash_ghost_interval
		player.spawn_dash_ghost()

	player.velocity.x = player.dash_dir * stats.dash_speed
	player.velocity.y = 0.0

	if player.dash_time <= 0.0:
		player.velocity.x = player.dash_dir * stats.dash_speed * stats.dash_end_speed_ratio
		if stats.dash_cooldown > 0.0:
			player.dash_cd = stats.dash_cooldown
		machine.transition_to("Fall" if not player.is_on_floor() else "Idle")


func post_move(_delta: float) -> void:
	if machine.current_state != self:
		return
	player.play_anim(stats.anim_dash)
