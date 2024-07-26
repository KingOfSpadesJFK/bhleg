extends Node2D

signal unlocked


func _on_collectible_collected():
	unlocked.emit()
	queue_free()
	
	# Unlock the keyhole
	get_tree().call_group("Keyhole", "_unlock_keyhole")
