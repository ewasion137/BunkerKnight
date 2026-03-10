extends CharacterBody2D

const BASE_SPEED = 400.0
const JUMP_VELOCITY = -600.0
const SLAM_SPEED = 1200.0
const MAX_COMBO = 7
const DASH_FORCE = 1200.0

var hop_combo = 0
var is_slamming = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dashing = false
var shake_strength = 0.0

func _physics_process(delta):
	# 1. Гравитация
	if not is_on_floor() and not is_slamming and not is_dashing:
		velocity.y += gravity * delta

	# 2. Ролл (Кувырок) - если комбо макс и мы в воздухе
	if hop_combo >= MAX_COMBO and not is_on_floor():
		$Sprite2D.rotation_degrees += 30 # Вращаем спрайт
	else:
		$Sprite2D.rotation_degrees = 0 # Сбрасываем поворот

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

	# 6. Движение
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		$Sprite2D.flip_h = (direction < 0)

	if Input.is_action_just_pressed("dash") and direction != 0 and not is_dashing:
		dash(direction)

	var current_speed = BASE_SPEED * (1.0 + (hop_combo * 0.05))

	if not is_slamming and not is_dashing:
		if direction != 0:
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, 80)

	# 7. Обновление UI (Лейбла скорости)
	# Проверь путь к лейблу! Если он внутри Player, то $CanvasLayer/SpeedLabel сработает
	if has_node("CanvasLayer/SpeedLabel"):
		$CanvasLayer/SpeedLabel.text = "Speed: " + str(int(velocity.x))

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
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, delta * 10)
		$Camera2D.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
