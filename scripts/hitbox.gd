extends Area2D
class_name HitBox

var invincible: bool

signal hit


func damage():
	if !invincible:
		hit.emit()
