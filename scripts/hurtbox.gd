extends Area2D
class_name Hurtbox

signal hurt
signal destroyed

@export var destroy_on_body: bool = false
@export var destroy_on_hit: bool = false

func _physics_process(_delta):
	for area: Area2D in get_overlapping_areas():
		if area is HitBox:
			hurt.emit()
			area.damage()
			if destroy_on_hit:
				_destroy()

	if destroy_on_body && has_overlapping_bodies():
		_destroy()


func _destroy():
	destroyed.emit()
	queue_free()
