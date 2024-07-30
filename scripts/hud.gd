extends Node

@export var level_name: String
@export var level_num: int
var player: Player
var cell_container
@onready var level_label = $HUD/LevelLabel

var _cell_tween: Tween
var _level_tween: Tween
@onready var _og_cell_pos: Vector2 = cell_container.position
@onready var _og_level_pos: Vector2 = level_label.position


func _enter_tree():
	cell_container = $HUD/CellContainer
	player = get_tree().get_first_node_in_group("Player")
	if player:
		cell_container.red_cells = player.red_cells
		cell_container.cyan_cells = player.cyan_cells


func _ready():
	if player:
		player.flash.connect(cell_container._on_player_flash)
	
	var act_label: Label = level_label.get_child(0)
	act_label.text = "ACT " + str(level_num)
	var name_label: Label = level_label.get_child(1)
	name_label.text = level_name
	level_label.position += Vector2(0, 512)
	_level_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	_level_tween.tween_property(level_label, "position", _og_level_pos, 1)
	_level_tween.tween_callback(_hide_level_label)


func _hide_level_label():
	await get_tree().create_timer(5).timeout
	_level_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	_level_tween.tween_property(level_label, "position", _og_level_pos + Vector2(0, 512), 1)
	_level_tween.tween_callback(level_label.queue_free)


func _process(_delta):
	# if player:
	# 	var cpos = Vector2.ZERO					# Top-left camera position
	# 	if player.has_node("Camera2D"):
	# 		cpos = player.get_node("Camera2D").global_position - get_viewport().get_visible_rect().size / 2
	# 	position = player.position - cpos		# Player position relative to window space
	# 	pass
	pass
