extends CharacterBody2D

# Константы движения
const BASE_SPEED = 400.0
const MAX_SPEED = 900.0
const JUMP_VELOCITY = -600.0
const SLAM_SPEED = 1200.0
const MAX_COMBO = 7
const ACCEL_PER_JUMP = 50.0
const DASH_FORCE = 1200.0

var hop_combo = 0
var is_rolling = false # Состояние кувырка
var is_slamming = false # Состояние удара вниз
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_speed = BASE_SPEED
var is_dashing = false

func _physics_process(delta):
	# Гравитация (обычная)
	if not is_on_floor() and not is_slamming:
		velocity.y += gravity * delta

	# Логика удара вниз (Slam)
	if Input.is_action_just_pressed("slam") and not is_on_floor():
		is_slamming = true
		velocity.x = 0
		velocity.y = SLAM_SPEED

	# Приземление (сброс состояний)
	if is_on_floor():
		if is_slamming:
			# Можно добавить экранную тряску тут
			is_slamming = false
		
		# Если мы стоим и не прыгаем, сбрасываем комбо
		if velocity.x == 0 and hop_combo > 0:
			hop_combo = 0
			is_rolling = false

	# Прыжок + Баннихоп
	if Input.is_action_just_pressed("jump") and is_on_floor():
		# Расчет скорости
		var speed_mult = 1.0 + (hop_combo * 0.02) # +2% за прыжок
		velocity.x = Input.get_axis("ui_left", "ui_right") * (BASE_SPEED * speed_mult)
		
		# Прыжок
		velocity.y = JUMP_VELOCITY
		
		# Инкремент комбо
		hop_combo += 1
		if hop_combo >= MAX_COMBO:
			is_rolling = true
			# Тут будет логика кувырка (например, изменение хитбокса или неуязвимость)
			print("ROLL MODE ACTIVATED!")
	
	# Горизонтальное движение (в воздухе управляем, но слабо)
	var direction = Input.get_axis("ui_left", "ui_right")
	if not is_slamming:
		if direction != 0:
			velocity.x = direction * (BASE_SPEED * (1.0 + (hop_combo * 0.02)))
		elif is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 50)

	move_and_slide()

func dash(dir):
	is_dashing = true
	# Импульс без обнуления velocity
	velocity.x = dir * DASH_FORCE
	
	# Длительность рывка
	await get_tree().create_timer(0.15).timeout 
	is_dashing = false
	apply_shake(5.0)
	
var shake_strength = 0.0

func apply_shake(strength):
	shake_strength = strength
	
func _process(delta):
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, delta * 10)
		$Camera2D.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
