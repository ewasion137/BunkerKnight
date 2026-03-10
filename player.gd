extends CharacterBody2D

# Константы движения
const BASE_SPEED = 400.0
const MAX_SPEED = 900.0
const ACCEL_PER_JUMP = 50.0 # На сколько разгоняемся с каждым прыжком
const JUMP_VELOCITY = -600.0
const DASH_FORCE = 1200.0

var current_speed = BASE_SPEED
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dashing = false

func _physics_process(delta):
	# Гравитация (если не в дэше)
	if not is_dashing and not is_on_floor():
		velocity.y += gravity * delta

	# БАННИХОП: Сброс скорости при приземлении, если не прыгнул сразу
	if is_on_floor():
		# Если стоим на месте или просто бежим - плавно возвращаем базу
		if current_speed > BASE_SPEED:
			current_speed = move_toward(current_speed, BASE_SPEED, 20)
	
	# Прыжок и разгон
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		# Разгон!
		current_speed = min(current_speed + ACCEL_PER_JUMP, MAX_SPEED)
	
	# Обрыв прыжка (Variable jump)
	elif Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# Движение
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Дэш
	if Input.is_action_just_pressed("dash") and direction != 0:
		dash(direction)
	
	if not is_dashing:
		if direction != 0:
			velocity.x = direction * current_speed
		else:
			# Трение
			velocity.x = move_toward(velocity.x, 0, 50)

	move_and_slide()

func dash(dir):
	is_dashing = true
	# Импульс без обнуления velocity
	velocity.x = dir * DASH_FORCE
	
	# Длительность рывка
	await get_tree().create_timer(0.15).timeout 
	is_dashing = false
