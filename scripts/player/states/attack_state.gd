extends PlayerState


func enter() -> void:
	if player.hitbox_shape:
		player.hitbox_shape.set_deferred("disabled", false)


func exit() -> void:
	if player.hitbox_shape:
		player.hitbox_shape.set_deferred("disabled", true)

	player.attack_playing = false
	player.attack_face_locked = false
	player.attack_buffered = false
	if player.sprite and player.sprite.speed_scale != 1.0:
		player.sprite.speed_scale = 1.0


func update(delta: float) -> void:
	if input.dash_just_pressed and player.can_dash():
		machine.transition_to("Dash")
		return

	player.try_jump()
	if machine.current_state != self:
		return

	if player.is_on_floor():
		var fr_scale: float = stats.idle_attack_friction_scale
		if player.combo_started_from_dash:
			fr_scale = stats.dash_attack_friction_scale
		elif player.combo_started_from_run:
			fr_scale = stats.run_attack_friction_scale
		player.apply_friction(delta, fr_scale)
	else:
		player.apply_horizontal(delta, stats.attack_move_speed_multiplier)
		player.apply_gravity(delta)

	if player.attack_playing and player.sprite.sprite_frames != null:
		if player.sprite.frame >= 2 and not player.attack_impulse_applied:
			var impulse: float = stats.idle_attack_impulse_force
			if player.combo_started_from_dash:
				impulse = stats.dash_attack_combo_impulse
			elif player.combo_started_from_run:
				impulse = stats.run_attack_combo_impulse
			player.velocity.x = player.facing_sign() * impulse
			player.attack_impulse_applied = true

	if input.attack_just_pressed and player.combo_step < 3:
		player.attack_buffered = true

