class_name PlayerStats
extends Resource

@export_group("Movement")
@export var walk_speed: float = 100.0
@export var run_speed: float = 250.0
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0
@export var jump_velocity: float = -550.0
@export var gravity_multiplier: float = 1.5
@export var run_threshold: float = 200.0
@export_range(0.1, 1.0, 0.05) var run_stick_threshold: float = 0.7
@export var jump_apex_epsilon: float = 40.0

@export_group("Jump Feel")
@export var coyote_time: float = 0.08
@export var jump_buffer_time: float = 0.1
@export var max_air_jumps: int = 1

@export_group("Dash")
@export var dash_duration: float = 0.25
@export var dash_speed: float = 500.0
@export var dash_end_speed_ratio: float = 0.08
@export var dash_cooldown: float = 0.3
@export var dash_in_air: bool = true
@export_flags("World", "Player", "Enemies", "Projectiles", "Hazards") var dash_phase_disable_mask: int = 0

@export_group("Dash Juice")
@export var dash_ghost_interval: float = 0.05
@export var dash_ghost_lifetime: float = 0.18
@export var dash_ghost_alpha: float = 0.55

@export_group("Attack")
@export var combo_window_time: float = 0.5
@export var attack_move_speed_multiplier: float = 0.4
@export var attack_face_lock: bool = true
@export var run_attack_start_frame_1: int = 1
@export var run_attack_start_frame_2: int = 2
@export var run_attack_start_frame_3: int = 0

@export_subgroup("Idle / standing attack")
@export var idle_attack_impulse_force: float = 400.0
@export_range(0.05, 3.0, 0.05) var idle_attack_friction_scale: float = 1.0

@export_subgroup("Run + attack combo")
@export var run_attack_open_impulse: float = 500.0
@export var run_attack_combo_impulse: float = 400.0
@export_range(0.05, 3.0, 0.05) var run_attack_friction_scale: float = 1.0

@export_subgroup("Dash + attack combo")
@export_range(0.0, 0.35, 0.01) var dash_attack_grace_time: float = 0.3
@export var dash_attack_start_frame: int = 1
@export_range(0.5, 2.5, 0.05) var dash_attack_anim_speed_scale: float = 1.0
@export_range(0.8, 1.25, 0.01) var dash_attack_velocity_carry: float = 1.0
@export var dash_attack_combo_impulse: float = 400.0
@export_range(0.05, 3.0, 0.05) var dash_attack_friction_scale: float = 1.0

@export_group("Animation Names")
@export var anim_idle: StringName = &"idle"
@export var anim_walk: StringName = &"walk"
@export var anim_run: StringName = &"run"
@export var anim_jump_start: StringName = &"jump-start"
@export var anim_jump_middle: StringName = &"jump-middle"
@export var anim_jump_fall: StringName = &"jump-fall"
@export var anim_dash: StringName = &"dash"
@export var anim_attack_1: StringName = &"attack"
@export var anim_attack_2: StringName = &"attack 2"
@export var anim_attack_3: StringName = &"attack 3"
@export var anim_air_attack: StringName = &"air attack"
