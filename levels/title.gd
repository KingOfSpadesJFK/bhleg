extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$BG.position += Vector2(0, 100.0 * _delta)
	if $BG.position.y >= 2048.0:
		$BG.position = Vector2($BG.position.x, 0)


func _on_new_game_pressed():
	Bhleg.change_scene("s1")


func _on_quit_game_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

