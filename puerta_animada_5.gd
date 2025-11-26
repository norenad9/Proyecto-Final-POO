extends Node2D

@export var destino: Node2D  # 👈 Asigna el destino desde el editor (por ejemplo: Destino1)

@onready var semi_abierta = $semi5
@onready var puerta_abierta = $puerta_abierta5
@onready var area = $Area2D5

var jugador_en_area = false
var jugador_ref: Node2D = null
var teletransportando = false  # Evita que se teletransporte dos veces seguidas

func _ready():
	# Asegurar estado inicial
	semi_abierta.visible = false
	puerta_abierta.visible = false
	
	# Conectar señales del área
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

# 🧍 Cuando el jugador entra al área
func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		jugador_en_area = true
		jugador_ref = body
		animar_apertura()

# 🚶 Cuando el jugador sale del área
func _on_body_exited(body):
	if body == jugador_ref:
		jugador_en_area = false
		jugador_ref = null
		cerrar_puerta()

# 🎬 Animación: semiabierta → abierta
func animar_apertura():
	if teletransportando:
		return  # Evita reabrir si ya se está usando la puerta
	semi_abierta.visible = true
	puerta_abierta.visible = false
	await get_tree().create_timer(0.1).timeout
	semi_abierta.visible = false
	puerta_abierta.visible = true
	print("🚪 Puerta abierta completamente")

# 🚪 Cerrar puerta
func cerrar_puerta():
	semi_abierta.visible = false
	puerta_abierta.visible = false
	print("🚪 Puerta cerrada")

# 🕹️ Detectar acción del jugador
func _process(delta):
	if jugador_en_area and not teletransportando and Input.is_action_just_pressed("ui_up"):
		teletransportando = true
		await teletransportar_jugador()
		teletransportando = false

# ✨ Teletransportar jugador al destino con seguridad
func teletransportar_jugador():
	if not jugador_ref:
		push_warning("⚠️ No hay jugador asignado, no se puede teletransportar.")
		return
	if not destino:
		push_warning("⚠️ No hay destino asignado para esta puerta.")
		return

	print("⏳ Teletransportando jugador...")

	# Esperar un instante para que se vea la animación
	await get_tree().create_timer(0.2).timeout

	# Teletransporte seguro
	if jugador_ref and destino:
		jugador_ref.global_position = destino.global_position
		print("🚀 Jugador teletransportado a", destino.name)
	else:
		push_warning("⚠️ Error: jugador o destino inválidos durante el teletransporte.")

	cerrar_puerta()
