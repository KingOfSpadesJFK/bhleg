extends Node2D

signal unlocked


func _on_collectible_collected():
	unlocked.emit()
	pass # Replace with function body.
