extends Control

@export var player: Player		# TEMPORARY!!! Use singleton instead


func _enter_tree():
	$CellContainer.red_cells = player.red_cells
	$CellContainer.cyan_cells = player.cyan_cells


func _ready():
	player.flash.connect($CellContainer._on_player_flash)
	pass # Replace with function body.


func _process(_delta):
	if player:
		var cpos = Vector2.ZERO					# Top-left camera position
		if player.has_node("Camera2D"):
			cpos = player.get_node("Camera2D").global_position - get_viewport().get_visible_rect().size / 2
		position = player.position - cpos		# Player position relative to window space
		pass
	pass
