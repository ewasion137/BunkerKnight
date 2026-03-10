extends CharacterBody2D

# Константы
const BASE_SPEED = 400.0
const MAX_SPEED = 900.0
const JUMP_VELOCITY = -600.0
const SLAM_SPEED = 1200.0
const MAX_COMBO = 7
const DASH_FORCE = 1200.0
const ACCEL = 1500.0 # Как быстро разгоняемся
const FRICTION = 800.0 # Как быстро тормозим (чем меньше число, тем дольше тормозит)

# Переменные
var hop_combo = 0
var is_slamming = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dashing = false
var shake_strength = 0.0

# ИСПРАВЛЕНИЕ ОШИБКИ: используем @onready
@onready var sprite = $Sprite2D
@onready var cam = $Camera2D

func _physics_process(delta):
	# 1. Гравитация
	if not is_on_floor() and not is_slamming and not is_dashing:
		velocity.y += gravity * delta

	# 2. Ролл
	if hop_combo >= MAX_COMBO and not is_on_floor():
		sprite.rotation_degrees += 30
	else:
		sprite.rotation_degrees = 0

	# 3. Удар вниз
	if Input.is_action_just_pressed("slam") and not is_on_floor():
		is_slamming = true
		velocity.y = SLAM_SPEED
		velocity.x = 0 

	# 4. Приземление
	if is_on_floor():
		is_slamming = false
		if abs(velocity.x) < 10:
			hop_combo = 0

	# 5. Прыжок
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if hop_combo < MAX_COMBO:
			hop_combo += 1

	# 6. Движение с ИНЕРЦИЕЙ
	var direction = Input.get_axis("ui_left", "ui_right")
	var current_speed = BASE_SPEED * (1.0 + (hop_combo * 0.05))

	if direction != 0:
		sprite.flip_h = (direction < 0)
		# Разгоняемся
		velocity.x = move_toward(velocity.x, direction * current_speed, ACCEL * delta)
	else:
		# Тормозим (FRICTION)
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Дэш
	if Input.is_action_just_pressed("dash") and direction != 0 and not is_dashing:
		dash(direction)

	if not is_dashing:
		move_and_slide()

func dash(dir):
	is_dashing = true
	velocity.x = dir * DASH_FORCE
	velocity.y = 0
	await get_tree().create_timer(0.15).timeout 
	is_dashing = false
	apply_shake(5.0)

func apply_shake(strength):
	shake_strength = strength
	
func _process(delta):
	# Обновление лейбла скорости (если есть)
	if has_node("CanvasLayer/SpeedLabel"):
		$CanvasLayer/SpeedLabel.text = "Speed: " + str(int(abs(velocity.x)))
		
	# Тряска
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, delta * 10)
		cam.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
