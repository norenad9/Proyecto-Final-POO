extends Area2D

# Configuración del comportamiento del prisionero
@export var shoot_interval: float = 1.0  # Tiempo entre disparos
@export var bullet_speed: float = 300.0
@export var switch_direction_time: float = 4.0
@export var bullet_damage: int = 1


# Referencias a nodos
@onready var sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else $Sprite2D if has_node("Sprite2D") else null
@onready var collision = $CollisionShape2D

# Variables internas
var is_active: bool = false
var shooting_left: bool = true
var shoot_timer: Timer
var direction_timer: Timer
var is_paused: bool = false

func _ready():
	add_to_group("prisoners")
	_setup_timers()
	deactivate()
	print("  🔫 Prisionero configurado:", name)

func _setup_timers():
	shoot_timer = Timer.new()
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_shoot)
	add_child(shoot_timer)

	direction_timer = Timer.new()
	direction_timer.wait_time = switch_direction_time
	direction_timer.one_shot = true
	direction_timer.timeout.connect(_switch_direction)
	add_child(direction_timer)

func activate():
	is_active = true
	is_paused = false
	shooting_left = true

	monitoring = true
	monitorable = true

	if sprite:
		sprite.flip_h = false
		if sprite.has_method("play"):
			sprite.play("idle")
		sprite.visible = true

	shoot_timer.start()
	direction_timer.start()
	print("    ✅ Prisionero ACTIVADO:", name)

	await get_tree().create_timer(0.5).timeout
	if is_active:
		_shoot()

func deactivate():
	is_active = false
	is_paused = false

	monitoring = false
	monitorable = false

	if shoot_timer:
		shoot_timer.stop()
	if direction_timer:
		direction_timer.stop()

	if sprite:
		sprite.visible = false
		if sprite.has_method("stop"):
			sprite.stop()

	print("    💤 Prisionero DESACTIVADO:", name)

func pause():
	is_paused = true
	shoot_timer.paused = true
	direction_timer.paused = true

func resume():
	is_paused = false
	shoot_timer.paused = false
	direction_timer.paused = false

func _shoot():
	if not is_active or is_paused:
		return

	print("    🔫 DISPARANDO desde", name)

	var bullet = _create_bullet()

	var facing_left = sprite.flip_h
	var offset_x = -70 if facing_left else 70
	var offset_y = 0

	bullet.global_position = global_position + Vector2(offset_x, offset_y)
	bullet.set("velocity", (Vector2.LEFT if facing_left else Vector2.RIGHT) * bullet_speed)

	get_tree().current_scene.add_child(bullet)




func _create_bullet() -> Area2D:
	var bullet = Area2D.new()
	bullet.name = "Bullet"
	bullet.z_index = 999
	bullet.add_to_group("enemy_bullets")

	# Visual
	var visual = ColorRect.new()
	visual.color = Color.RED
	visual.size = Vector2(25, 5)
	visual.position = Vector2(1185,1375)
	bullet.add_child(visual)

	# Colisión
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(25, 5)
	collision.shape = shape
	collision.position = Vector2(1185,1375)
	bullet.add_child(collision)

	# Asignar script
	bullet.set_script(load("res://Bullet.gd"))

	return bullet



func _switch_direction():
	if not is_active or is_paused:
		return

	shooting_left = not shooting_left
	if sprite:
		sprite.flip_h = not sprite.flip_h
	print("    🔄 Cambió dirección:", ("IZQUIERDA" if shooting_left else "DERECHA"))
