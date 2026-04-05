class_name Hurtbox
extends Area2D

signal received_damage(amount: int)


func _ready() -> void:
	monitorable = true


func apply_damage(amount: int) -> void:
	received_damage.emit(amount)
