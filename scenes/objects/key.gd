extends Node2D

signal unlocked


func _on_collectible_collected():
	unlocked.emit()
	visible = false
	
	# Unlock the keyhole
	get_tree().call_group("Keyhole", "_unlock_keyhole")
	$SFX.play()
	await $SFX.finished
	queue_free()
