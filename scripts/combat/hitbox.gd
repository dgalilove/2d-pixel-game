class_name Hitbox
extends Area2D

signal damage_dealt(amount: int)

@export var damage: int = 10
var collision_shape: Node


func _init() -> void:
	monitoring = true
	monitorable = true


func _ready() -> void:
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			collision_shape = child
			break

	if collision_shape == null:
		push_error("Hitbox has no CollisionShape2D/CollisionPolygon2D child.")


func _physics_process(_delta: float) -> void:
	if collision_shape == null:
		return
	if collision_shape is CollisionShape2D and (collision_shape as CollisionShape2D).disabled:
		return
	if collision_shape is CollisionPolygon2D and (collision_shape as CollisionPolygon2D).disabled:
		return

	var hit_any: bool = false
	for area in get_overlapping_areas():
		if area is Hurtbox:
			(area as Hurtbox).apply_damage(damage)
			hit_any = true

	if hit_any:
		damage_dealt.emit(damage)
		if collision_shape is CollisionShape2D:
			(collision_shape as CollisionShape2D).set_deferred("disabled", true)
		elif collision_shape is CollisionPolygon2D:
			(collision_shape as CollisionPolygon2D).set_deferred("disabled", true)
