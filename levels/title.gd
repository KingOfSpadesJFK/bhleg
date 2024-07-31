extends Node2D

var _joypad: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	# $CanvasLayer/MainMenu/BoxContainer/NewGame.grab_focus()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$BG.position += Vector2(0, 100.0 * _delta)
	if $BG.position.y >= 2048.0:
		$BG.position = Vector2($BG.position.x, -100)


func _on_new_game_pressed():
	Bhleg.change_scene("instructions")


func _on_quit_game_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _input(event):
	if !_joypad && (event is InputEventJoypadButton || event is InputEventJoypadMotion):
		_joypad = true
		$CanvasLayer/MainMenu/BoxContainer/NewGame.grab_focus()
		pass
	
	if event is InputEventMouse:
		_joypad = false
	pass
