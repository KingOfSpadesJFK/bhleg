extends Label

@export var kill_on_white: bool = true
@export var kill_on_red: bool
@export var kill_on_cyan: bool

func _on_player_flash(red_count, cyan_count):
	if kill_on_white:
		queue_free()
	if kill_on_red && red_count >= 5:
		queue_free()
	if kill_on_cyan && cyan_count >= 5:
		queue_free()
