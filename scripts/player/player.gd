extends CharacterBody2D

@export var stats: PlayerStats

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var input: InputHandler = $InputHandler
@onready var state_machine: StateMachine = $StateMachine

var dash_time: float = 0.0
var dash_cd: float = 0.0
var dash_dir: float = 1.0
var dash_ghost_time: float = 0.0
var dash_phase_active: bool = false
var saved_mask: int = 0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var air_jumps_used: int = 0

var combo_step: int = 0
var combo_window_timer: float = 0.0
var attack_buffered: bool = false
var attack_playing: bool = false
var attack_face_locked: bool = false
var attack_grounded: bool = false
var attack_impulse_applied: bool = false
var combo_started_from_run: bool = false
var combo_started_from_dash: bool = false
var dash_attack_grace_timer: float = 0.0


func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	state_machine.setup(self, input, stats)


func _physics_process(delta: float) -> void:
	input.poll()
	_tick_timers(delta)
	_update_coyote()

	state_machine.update(delta)

	move_and_slide()

	state_machine.post_move(delta)


func apply_horizontal(delta: float, speed_scale: float) -> void:
	var is_running: bool = input.direction_magnitude >= stats.run_stick_threshold
	var max_speed: float = stats.run_speed if is_running else stats.walk_speed
	if input.direction != 0.0:
		if not attack_face_locked:
			face_left(input.direction < 0.0)
		velocity.x = move_toward(velocity.x, signf(input.direction) * max_speed * speed_scale, stats.acceleration * speed_scale * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, stats.friction * delta)


func apply_friction(delta: float, friction_scale: float = 1.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, stats.friction * friction_scale * delta)


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	velocity.y += get_gravity().y * stats.gravity_multiplier * delta


func try_jump() -> void:
	if input.jump_just_pressed:
		jump_buffer_timer = stats.jump_buffer_time

	if jump_buffer_timer > 0.0:
		var grounded: bool = is_on_floor() or coyote_timer > 0.0
		if grounded:
			air_jumps_used = 0
			velocity.y = stats.jump_velocity
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			dash_attack_grace_timer = 0.0
			state_machine.transition_to("Jump")
		elif input.jump_just_pressed and air_jumps_used < stats.max_air_jumps:
			air_jumps_used += 1
			velocity.y = stats.jump_velocity
			jump_buffer_timer = 0.0
			dash_attack_grace_timer = 0.0
			if state_machine.current_state.name == &"Jump":
				force_anim(stats.anim_jump_start)
			else:
				state_machine.transition_to("Jump")


func try_dash() -> void:
	if input.dash_just_pressed and can_dash():
		state_machine.transition_to("Dash")


func can_dash() -> bool:
	if dash_cd > 0.0 or dash_time > 0.0:
		return false
	if not stats.dash_in_air and not is_on_floor():
		return false
	return true


func begin_dash() -> void:
	var dir: float = signf(input.direction)
	if dir == 0.0:
		dir = facing_sign()
	if dir == 0.0:
		dir = 1.0

	dash_dir = dir
	dash_time = stats.dash_duration
	dash_ghost_time = 0.0
	dash_attack_grace_timer = 0.0
	begin_dash_phase()
	face_left(dash_dir < 0.0)

	attack_playing = false
	attack_face_locked = false


func begin_dash_phase() -> void:
	if dash_phase_active:
		return
	saved_mask = collision_mask
	dash_phase_active = true
	if stats.dash_phase_disable_mask != 0:
		collision_mask = saved_mask & ~stats.dash_phase_disable_mask


func end_dash_phase() -> void:
	if not dash_phase_active:
		return
	collision_mask = saved_mask
	dash_phase_active = false


func spawn_dash_ghost() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var p := get_parent()
	if p == null:
		return

	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = sprite.sprite_frames
	ghost.animation = sprite.animation
	ghost.frame = sprite.frame
	ghost.speed_scale = 0.0
	ghost.global_position = global_position
	ghost.global_rotation = global_rotation
	ghost.scale = sprite.scale
	ghost.modulate = Color(1, 1, 1, stats.dash_ghost_alpha)
	ghost.z_index = sprite.z_index - 1
	p.add_child(ghost)

	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, stats.dash_ghost_lifetime)
	tween.finished.connect(ghost.queue_free)


func begin_dash_attack_grace() -> void:
	dash_attack_grace_timer = stats.dash_attack_grace_time


func try_attack() -> void:
	if not input.attack_just_pressed:
		return
	if state_machine.current_state.name == &"Dash":
		return

	if combo_window_timer > 0.0 and combo_step > 0 and combo_step < 3:
		start_attack(combo_step + 1)
	elif dash_attack_grace_timer > 0.0:
		start_dash_attack(false)
	else:
		start_attack(1)


func start_attack(step: int) -> void:
	combo_step = clampi(step, 1, 3)
	attack_buffered = false
	attack_playing = true
	attack_grounded = is_on_floor()
	combo_window_timer = 0.0
	dash_attack_grace_timer = 0.0

	if combo_step == 1:
		combo_started_from_run = (
			attack_grounded
			and absf(velocity.x) > stats.run_threshold
			and input.direction != 0.0
		)
		combo_started_from_dash = false

	if combo_step == 1 and combo_started_from_run:
		attack_impulse_applied = true
		velocity.x = facing_sign() * stats.run_attack_open_impulse
	else:
		attack_impulse_applied = false

	if input.direction != 0.0:
		face_left(input.direction < 0.0)

	if stats.attack_face_lock:
		attack_face_locked = true

	if state_machine.current_state.name != &"Attack":
		state_machine.transition_to("Attack")

	play_combo_anim()


func start_dash_attack(apply_dash_cooldown: bool = true) -> void:
	dash_time = 0.0
	dash_attack_grace_timer = 0.0
	if apply_dash_cooldown and stats.dash_cooldown > 0.0:
		dash_cd = stats.dash_cooldown

	combo_step = 1
	attack_buffered = false
	attack_playing = true
	attack_grounded = is_on_floor()
	combo_window_timer = 0.0
	combo_started_from_run = false
	combo_started_from_dash = true
	attack_impulse_applied = true
	velocity.x = dash_dir * stats.dash_speed * stats.dash_attack_velocity_carry

	face_left(dash_dir < 0.0)
	if stats.attack_face_lock:
		attack_face_locked = true

	state_machine.transition_to("Attack")
	play_combo_anim()


func play_combo_anim() -> void:
	if not attack_grounded:
		force_anim(stats.anim_air_attack)
		return

	var anim: StringName
	var run_frame: int = 0
	match combo_step:
		1:
			anim = stats.anim_attack_1
			run_frame = stats.run_attack_start_frame_1
		2:
			anim = stats.anim_attack_2
			run_frame = stats.run_attack_start_frame_2
		3:
			anim = stats.anim_attack_3
			run_frame = stats.run_attack_start_frame_3
		_:
			anim = stats.anim_attack_1
			run_frame = stats.run_attack_start_frame_1

	force_anim(anim)
	sprite.speed_scale = 1.0
	if combo_started_from_dash and combo_step == 1:
		sprite.speed_scale = stats.dash_attack_anim_speed_scale
		if sprite.sprite_frames != null:
			var fc: int = sprite.sprite_frames.get_frame_count(anim)
			if fc > stats.dash_attack_start_frame:
				sprite.frame = stats.dash_attack_start_frame
	elif combo_started_from_run and sprite.sprite_frames != null:
		var fc: int = sprite.sprite_frames.get_frame_count(anim)
		if fc > run_frame:
			sprite.frame = run_frame


func _on_sprite_animation_finished() -> void:
	if state_machine.current_state.name != &"Attack":
		return

	attack_playing = false
	attack_face_locked = false

	if attack_buffered and combo_step < 3:
		start_attack(combo_step + 1)
		return

	combo_window_timer = stats.combo_window_time
	state_machine.transition_to("Fall" if not is_on_floor() else "Idle")


func _tick_timers(delta: float) -> void:
	dash_cd = maxf(0.0, dash_cd - delta)
	dash_attack_grace_timer = maxf(0.0, dash_attack_grace_timer - delta)
	coyote_timer = maxf(0.0, coyote_timer - delta)
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	if not attack_playing and combo_window_timer > 0.0:
		combo_window_timer = maxf(0.0, combo_window_timer - delta)
		if combo_window_timer <= 0.0:
			combo_step = 0
			combo_started_from_run = false
			combo_started_from_dash = false


func _update_coyote() -> void:
	if is_on_floor():
		coyote_timer = stats.coyote_time
		was_on_floor = true
		air_jumps_used = 0
	elif was_on_floor:
		was_on_floor = false
	else:
		coyote_timer = 0.0


func play_anim(anim_name: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim_name):
		return
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func force_anim(anim_name: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim_name):
		return
	sprite.play(anim_name)


func face_left(is_left: bool) -> void:
	if sprite == null:
		return
	var mag: float = absf(sprite.scale.x)
	if mag < 0.0001:
		mag = 1.0
	sprite.scale.x = -mag if is_left else mag


func facing_sign() -> float:
	if sprite == null:
		return 1.0
	return -1.0 if sprite.scale.x < 0.0 else 1.0
