extends Area2D
class_name Hurtbox

signal hurt

func _physics_process(_delta):
	for area: Area2D in get_overlapping_areas():
		if area is HitBox:
			hurt.emit()
			area.damage()
