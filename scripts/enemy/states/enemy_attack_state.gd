extends EnemyState


func enter() -> void:
	_sync_attack_hitbox()


func exit() -> void:
	if enemy.hitbox_shape:
		enemy.hitbox_shape.disabled = true

	enemy.attack_playing = false
	enemy.attack_face_locked = false
	if enemy.sprite and enemy.sprite.speed_scale != 1.0:
		enemy.sprite.speed_scale = 1.0


func update(delta: float) -> void:
	enemy.try_jump()
	if machine.current_state != self:
		return

	enemy.face_toward_target_player()

	if enemy.is_on_floor():
		var fr_scale: float = stats.idle_attack_friction_scale
		if enemy.combo_started_from_run:
			fr_scale = stats.run_attack_friction_scale
		enemy.apply_friction(delta, fr_scale)
	else:
		enemy.apply_horizontal(delta, stats.attack_move_speed_multiplier)
		enemy.apply_gravity(delta)

	_sync_attack_hitbox()

	if enemy.attack_playing and enemy.sprite.sprite_frames != null:
		var anim_n: StringName = enemy.sprite.animation
		if enemy.sprite.sprite_frames.has_animation(anim_n):
			var fc_i: int = enemy.sprite.sprite_frames.get_frame_count(anim_n)
			var start_i: int = mini(stats.attack_hitbox_active_from_frame, maxi(0, fc_i - 1))
			if enemy.sprite.frame >= start_i and not enemy.attack_impulse_applied:
				var impulse: float = stats.idle_attack_impulse_force
				if enemy.combo_started_from_run:
					impulse = stats.run_attack_combo_impulse
				enemy.velocity.x = enemy.facing_sign() * impulse
				enemy.attack_impulse_applied = true


func _sync_attack_hitbox() -> void:
	if enemy.hitbox_shape == null or enemy.sprite == null or enemy.sprite.sprite_frames == null:
		return
	if not enemy.attack_playing:
		enemy.hitbox_shape.disabled = true
		return
	var anim_name: StringName = enemy.sprite.animation
	if not enemy.sprite.sprite_frames.has_animation(anim_name):
		enemy.hitbox_shape.disabled = true
		return
	var fc: int = enemy.sprite.sprite_frames.get_frame_count(anim_name)
	var start_f: int = mini(stats.attack_hitbox_active_from_frame, maxi(0, fc - 1))
	var active: bool = (
		fc > 0
		and enemy.sprite.frame >= start_f
		and not enemy.attack_hitbox_spent
	)
	enemy.hitbox_shape.disabled = not active
