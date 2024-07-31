extends Control


func _ready():
	$Button.grab_focus()


func _on_button_pressed():
	Bhleg.change_scene("s1")
