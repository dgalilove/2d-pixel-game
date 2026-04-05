class_name EnemyStats
extends Resource

@export_group("Movement")
@export var run_speed: float = 100.0
@export var acceleration: float = 1200.0
@export var friction: float = 2000.0
@export var jump_velocity: float = -500.0
@export var gravity_multiplier: float = 1.6
@export var run_threshold: float = 160.0
@export var jump_apex_epsilon: float = 40.0

@export_group("Jump Feel")
@export var coyote_time: float = 0.06
@export var jump_buffer_time: float = 0.08
@export var max_air_jumps: int = 0

@export_group("AI / Brain")
@export var aggro_distance: float = 420.0
@export var attack_range_x: float = 60.0
@export var attack_range_y: float = 72.0
@export var attack_cooldown: float = 1.5
@export var combo_followup_delay: float = 0.14
@export var jump_if_player_above: bool = true
@export var jump_height_threshold: float = 56.0
@export var jump_cooldown: float = 1.8

@export_group("Attack")
@export var combo_window_time: float = 0.0
@export var attack_hitbox_active_from_frame: int = 2
@export var attack_move_speed_multiplier: float = 0.3
@export var attack_face_lock: bool = true
@export var run_attack_start_frame_1: int = 1
@export var run_attack_start_frame_2: int = 2
@export var run_attack_start_frame_3: int = 0

@export_subgroup("Idle / standing attack")
@export var idle_attack_impulse_force: float = 320.0
@export_range(0.05, 3.0, 0.05) var idle_attack_friction_scale: float = 1.15

@export_subgroup("Run + attack combo")
@export var run_attack_open_impulse: float = 380.0
@export var run_attack_combo_impulse: float = 300.0
@export_range(0.05, 3.0, 0.05) var run_attack_friction_scale: float = 1.0

@export_group("Animation Names")
@export var anim_idle: StringName = &"purplehairgirl_idle"
@export var anim_run: StringName = &"purplehairgirl_run"
@export var anim_jump: StringName = &"purplehairgirl_jump"
@export var anim_attack_1: StringName = &"purplehairgirl_attack"
@export var anim_attack_2: StringName = &"purplehairgirl_attack_2"
@export var anim_attack_3: StringName = &"purplehairgirl_attack_3"