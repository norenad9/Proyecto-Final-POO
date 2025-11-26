extends CharacterBody2D

const SPEED = 260.0
const JUMP_VELOCITY = -370.0
const GRAVITY = 900.0
var mirando_derecha = true
var animated_sprite: AnimatedSprite2D  
var en_impulso = false  
var shield_active = false
var shield_on_cooldown = false
var shield_duration := 8.0
var shield_cooldown := 20.0
var shield_material := ShaderMaterial.new()

# NUEVO: Variables para tracking del tiempo
var shield_time_left := 0.0
var shield_cooldown_left := 0.0



func _input(event):
	if event.is_action_pressed("shield") and not shield_active and not shield_on_cooldown:
		activar_shield()

func activar_shield():
	shield_active = true
	shield_on_cooldown = true
	shield_time_left = shield_duration
	material = shield_material
	print("🛡️ ESCUDO ACTIVADO")

	# Timer exacto de 8 segundos para apagar escudo
	await get_tree().create_timer(shield_duration).timeout

	# Apagar escudo cuando termine el tiempo
	material = null
	shield_active = false
	print("⛔ ESCUDO TERMINADO")

	# Iniciar cooldown
	shield_cooldown_left = shield_cooldown



func _physics_process(delta):
	# NUEVO: Actualizar barra del escudo
		# Tiempo del escudo
	if shield_active:
		shield_time_left -= delta
		if shield_time_left <= 0:
			shield_time_left = 0

	# Tiempo del cooldown
	if shield_on_cooldown and not shield_active:
		shield_cooldown_left -= delta
		if shield_cooldown_left <= 0:
			shield_cooldown_left = 0
			shield_on_cooldown = false
			print("🟢 SHIELD READY TO USE")
	# Tu código de movimiento existente (sin cambios)
	if animated_sprite == null:
		return
	var direction = 0
	if Input.is_action_pressed("ui_right"):
		direction += 1
		mirando_derecha = true
	if Input.is_action_pressed("ui_left"):
		direction -= 1
		mirando_derecha = false
	velocity.x = direction * SPEED
	if not en_impulso:
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

var vidas = 3
func take_damage():
	if shield_active:
		print("ESCUDO BLOQUEA DAÑO")
		return
	vidas -= 1
	print("💔 Vida perdida! Restan:", vidas)
	var corazon = get_tree().current_scene.get_node_or_null("corazon" + str(vidas + 1))
	if corazon:
		corazon.visible = false
	# 🚫 Si está en minijuego, no recibe daño
	if get_tree().current_scene.minijuego_en_progreso:
		print("🛑 Daño bloqueado: jugador dentro de minijuego")
		return
	if vidas <= 0:
		print("💀 GAME OVER")
		get_tree().current_scene.call("mostrar_ventana_game_over")

func aplicar_rebote(fuerza: float):
	velocity.y = -fuerza
	animated_sprite.play("salto")
