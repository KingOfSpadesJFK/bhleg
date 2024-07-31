extends Control

func _ready():
	GlobalMusicPlayer.get_current_track().fade_out()

func _on_button_pressed():
	Bhleg.change_scene("test_level")
