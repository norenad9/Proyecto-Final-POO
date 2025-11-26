extends CharacterBody2D

const SPEED = 260.0
const JUMP_VELOCITY = -370.0
const CLIMB_SPEED = 120.0
const GRAVITY = 900.0

var en_escalera = false
var subiendo = false
var mirando_derecha = true

var animated_sprite: AnimatedSprite2D  # 🔗 Se asigna dinámicamente desde lab1.gd

func _ready():
	add_to_group("jugador")  # importante: para que los trampolines detecten al jugador

func _physics_process(delta):
	if animated_sprite == null:
		return  # Seguridad: aún no se asignó sprite

	var direction = 0

	# --- ESCALERAS ---
	if en_escalera and Input.is_action_pressed("ui_up"):
		subiendo = true
		velocity = Vector2.ZERO
		animated_sprite.play("climb")

	if subiendo:
		if Input.is_action_pressed("ui_up"):
			velocity.y = -CLIMB_SPEED
			animated_sprite.play("climb")
		elif Input.is_action_pressed("ui_down"):
			velocity.y = CLIMB_SPEED
			animated_sprite.play("climb")
		else:
			velocity.y = 0
			if animated_sprite.animation != "climb":
				animated_sprite.play("climb")
			animated_sprite.stop()

		velocity.x = 0

		if Input.is_action_just_pressed("ui_accept"):
			subiendo = false
			en_escalera = true
			velocity.y = JUMP_VELOCITY

			if Input.is_action_pressed("ui_left"):
				mirando_derecha = false
			elif Input.is_action_pressed("ui_right"):
				mirando_derecha = true

			animated_sprite.flip_h = not mirando_derecha
			animated_sprite.play("salto")

		if is_on_floor():
			subiendo = false
			if not Input.is_action_pressed("ui_up"):
				animated_sprite.play("idle")

		move_and_slide()
		return

	# --- MOVIMIENTO NORMAL ---
	if Input.is_action_pressed("ui_right"):
		direction += 1
		mirando_derecha = true
	if Input.is_action_pressed("ui_left"):
		direction -= 1
		mirando_derecha = false

	velocity.x = direction * SPEED

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animated_sprite.flip_h = not mirando_derecha
		animated_sprite.play("salto")

	if is_on_floor():
		if direction != 0:
			animated_sprite.play("run")
			animated_sprite.flip_h = not mirando_derecha
		else:
			animated_sprite.play("idle")
	else:
		animated_sprite.play("salto")
		animated_sprite.flip_h = not mirando_derecha

	move_and_slide()

# --- MÉTODO PARA REBOTE DEL TRAMPOLÍN ---
func aplicar_rebote(fuerza: float):
	velocity.y = -fuerza
	if animated_sprite:
		animated_sprite.play("salto")
