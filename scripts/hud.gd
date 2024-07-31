extends Node

@export var level_name: String
@export var level_num: int
var player: Player
var cell_container
@onready var level_label = $HUD/LevelLabel

var _cell_tween: Tween
var _level_tween: Tween
var _pause_tween: Tween
@onready var _og_cell_pos: Vector2 = cell_container.position
@onready var _og_level_pos: Vector2 = level_label.position
@onready var _og_pause_pos: Vector2 = $Pause/Margin.position
var _paused: bool = false


func _enter_tree():
	cell_container = $HUD/CellContainer
	player = get_tree().get_first_node_in_group("Player")
	if player:
		cell_container.red_cells = player.red_cells
		cell_container.cyan_cells = player.cyan_cells


func _ready():
	if player:
		player.flash.connect(cell_container._on_player_flash)
		player.flash.connect(_on_player_flash)
		player.changed_flash_type.connect(_on_player_changed_flash_type)
		_on_player_flash(0,0)
		_on_player_changed_flash_type(player.flash_type)
	
	var act_label: Label = level_label.get_child(0)
	act_label.text = "ACT " + str(level_num)
	var name_label: Label = level_label.get_child(1)
	name_label.text = level_name
	level_label.position += Vector2(0, 512)
	_level_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	_level_tween.tween_property(level_label, "position", _og_level_pos, 1)
	_level_tween.tween_callback(_hide_level_label)
	
	$Pause/Margin.position += Vector2(0,512)


func _on_player_flash(_red: int, _cyan: int):
	var change_mod: Callable = func(node: CanvasItem, color: Color, enough: bool):
		if enough:
			node.modulate = color
		else:
			node.modulate = Color.html("#28325580")
			
	change_mod.call($HUD/FlashTypeContainer/White, Color.WHITE, player._has_enough_for_white())
	change_mod.call($HUD/FlashTypeContainer/Red,   Color.html("#e04500"), player._has_enough_for_red())
	change_mod.call($HUD/FlashTypeContainer/Cyan,  Color.html("#00c9ff"), player._has_enough_for_cyan())


func _on_player_changed_flash_type(type: Player.FlashType):
	var pos: Vector2 = $HUD/FlashTypeContainer/White.position
	match type:
		Player.FlashType.WHITE:
			pos = $HUD/FlashTypeContainer/White.position
			if !player._has_enough_for_white():
				$HUD/FlashTypeContainer/White.modulate = Color.html("#28325580")
		Player.FlashType.RED:
			pos = $HUD/FlashTypeContainer/Red.position
			if !player._has_enough_for_red():
				$HUD/FlashTypeContainer/Red.modulate = Color.html("#28325580")
		Player.FlashType.CYAN:
			pos = $HUD/FlashTypeContainer/Cyan.position
			if !player._has_enough_for_cyan():
				$HUD/FlashTypeContainer/Cyan.modulate = Color.html("#28325580")
		
	$HUD/SelectedFlash.position = pos


func _hide_level_label():
	await get_tree().create_timer(5).timeout
	_level_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	_level_tween.tween_property(level_label, "position", _og_level_pos + Vector2(0, 512), 1)
	_level_tween.tween_callback(level_label.queue_free)
	

func _input(event):		
	if event is InputEventKey || event is InputEventJoypadButton:
		if event.is_action_pressed("ui_pause") && !(_pause_tween && _pause_tween.is_running()):
			_pause_unpause()
			

func _pause_unpause():
	var end_pause: Callable = func():
		if !_paused:
			$Pause.visible = false
		_pause_tween.kill()
		
	$Pause.visible = true
	_pause_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if _paused:
		get_tree().paused = false
		$Pause/Panel.visible = false
		_pause_tween.tween_property($Pause/Margin, "position", _og_pause_pos + Vector2(0,512), 0.45)
	else:
		get_tree().paused = true
		$Pause/Panel.visible = true
		_pause_tween.tween_property($Pause/Margin, "position", _og_pause_pos, .45)
	_pause_tween.tween_callback(end_pause)
	_paused = !_paused


func _on_resume_pressed():
	if !(_pause_tween && _pause_tween.is_running()):
		_pause_unpause()


func _on_retry_pressed():
	get_tree().paused = false
	$Pause/Panel.visible = false
	Bhleg.reload_scene()


func _on_quit_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
