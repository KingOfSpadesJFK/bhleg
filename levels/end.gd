extends Control

func _ready():
	if GlobalMusicPlayer.get_current_track():
		GlobalMusicPlayer.get_current_track().fade_out()
	$Button.grab_focus()

func _on_button_pressed():
	Bhleg.change_scene("test_level")
