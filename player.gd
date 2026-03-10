extends CharacterBody2D

const SPEED = 400.0
const JUMP_VELOCITY = -600.0
const DASH_SPEED = 1200.0
const DASH_DURATION = 0.2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dashing = false
var can_dash = true
var last_direction = 1 # Чтобы дэшить даже если стоишь на месте

func _physics_process(delta):
	# Если мы в дэше, гравитация не работает, просто летим
	if is_dashing:
		return

	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta

	# Прыжок (Variable Jump - отпускаешь кнопку, прыжок обрывается)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5 # Обрываем прыжок (чем меньше число, тем короче прыжок)

	# Движение
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		last_direction = direction # Запоминаем направление
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.2) # Трение (торможение)

	# Дэш
	if Input.is_action_just_pressed("dash") and can_dash:
		perform_dash(last_direction)

	move_and_slide()

func perform_dash(dir):
	is_dashing = true
	can_dash = false
	
	var old_gravity = velocity.y
	velocity.y = 0 # Чтобы не падать во время дэша
	velocity.x = dir * DASH_SPEED
	
	await get_tree().create_timer(DASH_DURATION).timeout
	
	is_dashing = false
	velocity.y = old_gravity # Возвращаем гравитацию
	
	# Кулдаун дэша (можно настроить под себя)
	await get_tree().create_timer(0.5).timeout 
	can_dash = true
