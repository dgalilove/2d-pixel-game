extends CharacterBody2D

@export var stats: EnemyStats

@onready var pivot: Node2D = $Pivot
@onready var sprite: AnimatedSprite2D = $Pivot/AnimatedSprite2D
@onready var attack_hitbox: Hitbox = $Pivot/Hitbox
@onready var hitbox_shape: CollisionShape2D = $Pivot/Hitbox/CollisionShape2D
@onready var state_machine: EnemyStateMachine = $StateMachine

@export var max_health: int = 30
var current_health: int
@onready var hurtbox: Area2D = $Hurtbox

## Bot sets each physics tick: horizontal intent -1..1 (0 = no move).
var intent_direction: float = 0.0
## True for one tick when the bot wants to jump (same idea as a single input press).
var intent_jump: bool = false
## True for one tick when the bot wants to press attack (combo / buffer).
var intent_attack: bool = false

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var air_jumps_used: int = 0

var combo_step: int = 0
var attack_playing: bool = false
var attack_face_locked: bool = false
var attack_grounded: bool = false
var attack_impulse_applied: bool = false
var combo_started_from_run: bool = false
## Which attack clip to play next: 0 → attack_1, 1 → attack_2, 2 → attack_3, then wraps.
var attack_anim_cycle: int = 0
## True after this swing's hitbox has tagged a hurtbox (prevents re-enabling shape every frame).
var attack_hitbox_spent: bool = false

var _attack_anim_elapsed: float = 0.0


func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	state_machine.setup(self, stats)
	if attack_hitbox:
		attack_hitbox.damage_dealt.connect(_on_attack_hitbox_damage_dealt)

	current_health = max_health


func _on_attack_hitbox_damage_dealt(_amount: int) -> void:
	attack_hitbox_spent = true


func _physics_process(delta: float) -> void:
	_bot_tick(delta)
	_tick_timers(delta)
	_update_coyote()

	state_machine.update(delta)

	move_and_slide()

	_check_air_attack_cancel_on_land()

	state_machine.post_move(delta)

	_sync_pivot_facing()


func _bot_tick(delta: float) -> void:
	var brain := get_node_or_null("Brain")
	if brain and brain.has_method(&"tick"):
		brain.tick(delta)


func apply_horizontal(delta: float, speed_scale: float) -> void:
	if intent_direction != 0.0:
		if not attack_face_locked:
			face_left(intent_direction < 0.0)
		velocity.x = move_toward(
			velocity.x,
			signf(intent_direction) * stats.run_speed * speed_scale,
			stats.acceleration * speed_scale * delta
		)
	else:
		velocity.x = move_toward(velocity.x, 0.0, stats.friction * delta)


func apply_friction(delta: float, friction_scale: float = 1.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, stats.friction * friction_scale * delta)


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	velocity.y += get_gravity().y * stats.gravity_multiplier * delta


func try_jump() -> void:
	var jump_edge: bool = intent_jump
	intent_jump = false

	if jump_edge:
		jump_buffer_timer = stats.jump_buffer_time

	if jump_buffer_timer > 0.0:
		var grounded: bool = is_on_floor() or coyote_timer > 0.0
		if grounded:
			air_jumps_used = 0
			velocity.y = stats.jump_velocity
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			state_machine.transition_to("Jump")
		elif jump_edge and air_jumps_used < stats.max_air_jumps:
			air_jumps_used += 1
			velocity.y = stats.jump_velocity
			jump_buffer_timer = 0.0
			if state_machine.current_state.name == &"Jump":
				play_jump_anim_manual(0)
			else:
				state_machine.transition_to("Jump")


func _check_air_attack_cancel_on_land() -> void:
	if state_machine.current_state.name != &"Attack":
		return
	if not attack_playing:
		return
	if attack_grounded:
		return
	if not is_on_floor():
		return

	combo_step = 0
	attack_playing = false
	attack_face_locked = false
	state_machine.transition_to("Idle")


func try_attack() -> void:
	if not intent_attack:
		return
	intent_attack = false
	if state_machine.current_state.name == &"Attack":
		return
	start_attack(1)


func start_attack(step: int) -> void:
	combo_step = clampi(step, 1, 3)
	attack_playing = true
	attack_hitbox_spent = false
	attack_grounded = is_on_floor()

	if combo_step == 1:
		combo_started_from_run = (
			attack_grounded
			and absf(velocity.x) > stats.run_threshold
			and intent_direction != 0.0
		)

	if not face_toward_target_player():
		if intent_direction != 0.0:
			face_left(intent_direction < 0.0)

	if combo_step == 1 and combo_started_from_run:
		attack_impulse_applied = true
		velocity.x = facing_sign() * stats.run_attack_open_impulse
	else:
		attack_impulse_applied = false

	if stats.attack_face_lock:
		attack_face_locked = true

	if state_machine.current_state.name != &"Attack":
		state_machine.transition_to("Attack")

	play_combo_anim()


func play_combo_anim() -> void:
	_attack_anim_elapsed = 0.0
	var slot: int = posmod(attack_anim_cycle, 3)
	attack_anim_cycle = posmod(attack_anim_cycle + 1, 3)

	var anim: StringName
	var run_frame: int = 0
	match slot:
		0:
			anim = stats.anim_attack_1
			run_frame = stats.run_attack_start_frame_1
		1:
			anim = stats.anim_attack_2
			run_frame = stats.run_attack_start_frame_2
		2:
			anim = stats.anim_attack_3
			run_frame = stats.run_attack_start_frame_3
		_:
			anim = stats.anim_attack_1
			run_frame = stats.run_attack_start_frame_1

	if not attack_grounded:
		force_anim(anim)
		return

	force_anim(anim)
	sprite.speed_scale = 1.0
	if combo_started_from_run and sprite.sprite_frames != null:
		var fc: int = sprite.sprite_frames.get_frame_count(anim)
		if fc > run_frame:
			sprite.frame = run_frame


func _on_sprite_animation_finished() -> void:
	_finish_current_attack_segment()


func _sprite_animation_duration(anim_name: StringName) -> float:
	var sf := sprite.sprite_frames
	if sf == null or not sf.has_animation(anim_name):
		return 0.4
	var fc: int = sf.get_frame_count(anim_name)
	if fc <= 0:
		return 0.4
	var total: float = 0.0
	for i in range(fc):
		total += sf.get_frame_duration(anim_name, i)
	return total / maxf(sprite.speed_scale, 0.001)


func _attack_animation_is_looping() -> bool:
	var sf := sprite.sprite_frames
	if sf == null or not sf.has_animation(sprite.animation):
		return false
	return sf.get_animation_loop(sprite.animation)


func _finish_current_attack_segment() -> void:
	if state_machine.current_state.name != &"Attack":
		return
	if not attack_playing:
		return

	attack_playing = false
	attack_face_locked = false
	_attack_anim_elapsed = 0.0

	var brain := get_node_or_null("Brain") as EnemyBrain

	if (
		stats.combo_window_time > 0.0
		and attack_grounded
		and is_on_floor()
		and brain != null
		and brain.is_target_in_attack_range()
		and combo_step < 3
	):
		start_attack(combo_step + 1)
		return

	combo_step = 0
	combo_started_from_run = false

	if brain != null:
		brain.set_attack_cooldown(stats.attack_cooldown)

	if not is_on_floor():
		state_machine.transition_to("Jump")
	else:
		state_machine.transition_to("Idle")


func _tick_timers(delta: float) -> void:
	coyote_timer = maxf(0.0, coyote_timer - delta)
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	if attack_playing and state_machine.current_state.name == &"Attack":
		if _attack_animation_is_looping():
			_attack_anim_elapsed += delta
			var dur: float = _sprite_animation_duration(sprite.animation)
			if dur > 0.0 and _attack_anim_elapsed >= dur:
				_finish_current_attack_segment()


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
	# After jump, sprite.pause() keeps the last clip frozen; same-name check alone never calls play() again.
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)


func force_anim(anim_name: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim_name):
		return
	sprite.play(anim_name)


## Single jump clip: frame 0 = rise, 1 = apex, 2 = fall. Pauses playback so phases are driven manually.
func play_jump_anim_manual(phase_frame: int) -> void:
	if sprite == null or stats == null or sprite.sprite_frames == null:
		return
	var anim: StringName = stats.anim_jump
	if not sprite.sprite_frames.has_animation(anim):
		return
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.pause()
	var fc: int = sprite.sprite_frames.get_frame_count(anim)
	if fc <= 0:
		return
	sprite.frame = clampi(phase_frame, 0, fc - 1)


## Returns true if a valid brain target was used to set facing (hitbox/sprite side).
func face_toward_target_player() -> bool:
	var brain := get_node_or_null("Brain") as EnemyBrain
	if brain == null or brain.target == null or not is_instance_valid(brain.target):
		return false
	var dx: float = brain.target.global_position.x - global_position.x
	face_left(dx < 0.0)
	return true


func face_left(is_left: bool) -> void:
	if pivot == null:
		return
	var mag: float = absf(pivot.scale.x)
	if mag < 0.0001:
		mag = 1.0
	pivot.scale.x = -mag if is_left else mag


func facing_sign() -> float:
	if pivot == null:
		return 1.0
	return -1.0 if pivot.scale.x < 0.0 else 1.0


func _sync_pivot_facing() -> void:
	if pivot == null:
		return
	if attack_face_locked:
		return
	var face_sign: float = 0.0
	if intent_direction != 0.0:
		face_sign = signf(intent_direction)
	elif velocity.x > 0.0:
		face_sign = 1.0
	elif velocity.x < 0.0:
		face_sign = -1.0
	else:
		return
	var mag: float = absf(pivot.scale.x)
	if mag < 0.0001:
		mag = 1.0
	pivot.scale.x = -mag if face_sign < 0.0 else mag


func _on_hurtbox_received_damage(amount: int) -> void:
	current_health -= amount
	print("Enemy hit! HP remaining: ", current_health)

	if current_health <= 0:
		queue_free()
		return

	if state_machine.current_state.name != &"Idle":
		state_machine.transition_to("Idle")
		var brain := get_node_or_null("Brain") as EnemyBrain
		if brain:
			brain.set_attack_cooldown(stats.attack_cooldown)
