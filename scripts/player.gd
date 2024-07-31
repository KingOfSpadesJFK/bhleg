extends CharacterBody2D
class_name Player

const WHITE_COLOR: Color = Color(1, 1, 1, 0.5)
const RED_COLOR: Color = Color(224.0/255.0, 69.0/255.0, 0.0, 0.5)
const OVERLAY_SHADOW: Color = Color(.35, .35, .35, .20)

var _laser_beam: PackedScene = preload("res://scenes/objects/laser_beam.tscn")

const SPEED = 150.0
const JUMP_VELOCITY = -350.0
const FLASH_RAY_LENGTH = 1000.0
const FLASH_SPREAD = 90.0			# How wide the area of flash should be (in degrees)
const FLASH_SAMPLES = 200
const TERMINAL_VELOCITY = 400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var damp: float = 0.0

# The static body to draw over
@export var shadow_body: LightBody

# The light cells of the player
@export var red_cells: int = 10
@export var cyan_cells: int = 10

# What type of flash the player is using
var flash_type: FlashType = FlashType.WHITE
var _flash_order_index: int = 0
var _flash_order: Array[FlashType] = [FlashType.WHITE, FlashType.RED, FlashType.CYAN]

# Which flashes to allow
@export var allow_white: bool = true
@export var allow_red: bool = true
@export var allow_cyan: bool = true

# Which direction the player is walking towards
var direction: float = 1.0

# Necessary nodes
@onready var _flash_light: FlashLight = $FlashAnchor/FlashLight
@onready var _anim_tree: AnimationTree = $Blob/AnimationTree
@onready var _eyes_sprite: Node2D = $Blob/Eyes/Sprite

var _overlay_tween: Tween
var _block_player_input: bool = false
var _blob_dir: float = direction
var _eyes_angle: float = 0.0
var _mouse_position: Vector2 = Vector2.ZERO
var _do_flash: FlashType = FlashType.NONE
var _flash_angle: float :
	set(value):
		_flash_angle = value
		$FlashAnchor.rotation = deg_to_rad(value)
		pass

var _using_joystick: bool
@onready var _camera: Camera2D = $Camera2D

# Stuff for player stuff between frames
@onready var _prev_pos: Vector2 = position
@onready var _prev_scale: Vector2 = scale
@onready var _prev_rot: float = rotation
@onready var _next_pos: Vector2 = position
@onready var _next_scale: Vector2 = scale
@onready var _next_rot: float = rotation
@onready var _frame_delta: float

signal flash(red_count: int, cyan_count: int)
signal changed_flash_type(type: FlashType)
signal death

enum FlashType {
	NONE,
	WHITE,
	RED,
	CYAN,
}


func _ready():
	if _anim_tree:
		_anim_tree.active = true
	_fade_overlay_colors()


func _process(_delta):
	if !_using_joystick:
		_flash_angle = _calculate_flash_direction(_mouse_position)
	position = lerp(position, _next_pos, _delta / _frame_delta)


func _physics_process(delta):	
	# Restore next and backup prev
	position = _next_pos
	rotation = _next_rot
	scale    = _next_scale
	_prev_pos   = position
	_prev_rot   = rotation
	_prev_scale = scale
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle terminal velocity
	if velocity.y > TERMINAL_VELOCITY - damp * 20.0:
		velocity.y = lerp(velocity.y, TERMINAL_VELOCITY, (10.0 + damp * 10.0) * delta)
	
	# Handle damping
	if damp:
		velocity = lerp(velocity, Vector2.ZERO, damp / 2.0 * delta)

	# Handle jump.
	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		$JumpSFX.play()
		velocity.y = JUMP_VELOCITY

	# Handle player direction
	var dir = Input.get_axis("player_left", "player_right")
	if !_block_player_input && dir:
		direction = dir
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, 1000.0 * delta)

	# Do flash routine 
	#  MUST BE DONE IN _physics_step()!!!
	if !(_do_flash == FlashType.NONE || _do_flash == FlashType.CYAN):
		_flash_light.flash_light(_do_flash == FlashType.RED)
		_do_flash = FlashType.NONE
		$FlashSFX.play()

	move_and_slide()
	_update_animation_parameters(delta)

	# Backup next and restore prev
	_next_pos   = position
	_next_rot   = rotation
	_next_scale = scale
	position = _prev_pos
	rotation = _prev_rot
	scale    = _prev_scale
	_frame_delta = delta


# Function for alot of the visual stuff
func _update_animation_parameters(_delta: float):
	_anim_tree["parameters/conditions/is_idle"] = is_on_floor() && velocity.is_zero_approx()
	_anim_tree["parameters/conditions/is_moving"] = is_on_floor() && !velocity.is_zero_approx()
	_anim_tree["parameters/conditions/is_airborne"] = !is_on_floor()
	_anim_tree["parameters/conditions/is_grounded"] = is_on_floor()

	_eyes_angle = lerp_angle(_eyes_angle, deg_to_rad(_flash_angle), 15.0 * _delta)
	$FlashOverlay.rotation = _eyes_angle
	var normal = Vector2(cos(_eyes_angle), sin(_eyes_angle))
	_eyes_sprite.position = normal * 3.0 - Vector2(_blob_dir, 0.0)

	# Update the blend positions
	_blob_dir = lerp(_blob_dir, direction, 8.0 * _delta)
	_anim_tree["parameters/Idle/blend_position"] = _blob_dir
	_anim_tree["parameters/Walk/blend_position"] = _blob_dir
	_anim_tree["parameters/Airborne/blend_position"] = Vector2(_blob_dir, velocity.y / 100.0)
	

func _has_enough_for_white() -> bool: return red_cells >= 1 && cyan_cells >= 1
func _has_enough_for_red() -> bool: return red_cells >= 5
func _has_enough_for_cyan() -> bool: return cyan_cells >= 5


# Should cyan and red switch?
#  Red should be the floaty stuff?
#  Cyan should be the laser beam?
func _input(event):
	if _block_player_input:
		return
	
	# Since there's probs only gonna be one place we'll need this, put it here
	#  A check to see if we should do the flash or not
	var _flash_check: Callable = func() -> FlashType:		
		if event.is_action_pressed("player_flash"):
			match flash_type:
				FlashType.WHITE:
					if _has_enough_for_white():
						red_cells -= 1
						cyan_cells -= 1
						flash.emit(1, 1)
						return FlashType.WHITE
				FlashType.RED:
					if _has_enough_for_red():
						red_cells -= 5
						flash.emit(5, 0)
						return FlashType.RED
				FlashType.CYAN:
					if _has_enough_for_cyan():	# Shoot a laser for cyan
						cyan_cells -= 5
						flash.emit(0, 5)
						var b = _laser_beam.instantiate()
						b.position = $FlashAnchor/BeamPoint.global_position
						b.rotation = deg_to_rad(_flash_angle)
						add_sibling(b)
						$LaserbeamSFX.play()
						return FlashType.NONE
				_:
					return FlashType.NONE	
		
		return FlashType.NONE
	
	if event is InputEventJoypadMotion:
		_using_joystick = true
		var v = Input.get_vector("player_aim_left", "player_aim_right", "player_aim_up", "player_aim_down")
		if v.length() > 0.75:
			_flash_angle = snapped(rad_to_deg(atan2(v.y, v.x)), 45.0)

	if event is InputEventMouseButton || event is InputEventJoypadMotion:
		if  is_on_floor() && $CooldownTimer.is_stopped():
			# Activate... the flash!
			_using_joystick = event is InputEventJoypadMotion
			_do_flash = _flash_check.call()
			if _do_flash:
				if !_using_joystick:
					_mouse_position = event.position
					_flash_angle = _calculate_flash_direction(_mouse_position)
				else:
					var v = Input.get_vector("player_aim_left", "player_aim_right", "player_aim_up", "player_aim_down")
					if v.length() > 0.75:
						_flash_angle = snapped(rad_to_deg(atan2(v.y, v.x)), 45.0)
				$CooldownTimer.start()
				$FlashOverlay/RedWhite/Light.modulate.a = 0.0
				$FlashOverlay/RedWhite/Shadow.modulate.a = 0.0
	
	if event is InputEventMouse:
		_using_joystick = false
		_mouse_position = event.position
	
	# Handle switching the flash type
	if event is InputEventKey || event is InputEventJoypadButton:
		if event.is_action_pressed("player_switch_flash") || event.is_action_pressed("player_switch_flash_reverse"):
			if $CooldownTimer.is_stopped():
				var reverse: bool = event.is_action_pressed("player_switch_flash_reverse") 
				_flash_order_index = (_flash_order_index + (-1 if reverse else 1)) % _flash_order.size()
				if _flash_order_index < 0:
					_flash_order_index += _flash_order.size()
				flash_type = _flash_order[_flash_order_index]
				changed_flash_type.emit(flash_type)
				_fade_overlay_colors()


func _fade_overlay_colors():
	if _overlay_tween:
		_overlay_tween.kill()
	_overlay_tween = get_tree().create_tween()
	var light = $FlashOverlay/RedWhite/Light.modulate
	var shade = $FlashOverlay/RedWhite/Shadow.modulate
	var dur = 0.15

	match flash_type:
		FlashType.WHITE:
			light = WHITE_COLOR
			shade = OVERLAY_SHADOW
			if !_has_enough_for_white():
				light.a = 0
				shade.a = 0
			_overlay_tween.tween_property($FlashOverlay/Cyan, "modulate", Color(1,1,1,0), dur)
			# print("Switched to white light")
		FlashType.RED:
			light = RED_COLOR
			shade = OVERLAY_SHADOW
			if !_has_enough_for_red():
				light.a = 0
				shade.a = 0
			_overlay_tween.tween_property($FlashOverlay/Cyan, "modulate", Color(1,1,1,0), dur)
			# print("Switiched to red light")
		FlashType.CYAN:
			light = WHITE_COLOR
			light.a = 0.0
			shade.a = 0.0
			if _has_enough_for_cyan():
				_overlay_tween.tween_property($FlashOverlay/Cyan, "modulate", Color(1,1,1,0.75), dur)
			else:
				_overlay_tween.tween_property($FlashOverlay/Cyan, "modulate", Color(1,1,1,0), dur)
			# print("Switched to cyan light")

	_overlay_tween.tween_property($FlashOverlay/RedWhite/Light, "modulate", light, dur)
	_overlay_tween.tween_property($FlashOverlay/RedWhite/Shadow, "modulate", shade, dur)


func _calculate_flash_direction(mouse_pos: Vector2):
	var result: float = 0
	var cpos = get_viewport().get_visible_rect().size / 2	# Center camera position
	if _camera:
		cpos = _camera.global_position
	mouse_pos -= get_viewport().get_visible_rect().size / 2
	var epos = cpos + (mouse_pos)								# Event position relative to world space
	var n = (epos - global_position).normalized()
	if n.is_zero_approx():
		result = 0.0
	else:
		result = rad_to_deg(atan2(n.y, n.x))
		var q: float = snapped(result, 45.0)
		result = q
		
	return result


func _on_hit_box_hit():
	$DeathSFX.play()
	$HitBox.queue_free()
	death.emit()
	_block_player_input = true
	_anim_tree.active = false
	$Blob/AnimationPlayer.play("death")
	await $Blob/AnimationPlayer.animation_finished
	# queue_free()
	visible = false
	Bhleg.reload_scene()


func _on_cooldown_timer_timeout():
	_fade_overlay_colors()
