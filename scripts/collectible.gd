extends Node2D
class_name Collectible

signal collected


func _on_area_2d_body_entered(body):
	if body is Player:
		collected.emit()
		queue_free()
