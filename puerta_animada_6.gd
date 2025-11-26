extends Node2D

@export var destino: Node2D  # Asigna el destino desde el editor (por ejemplo: Destino1)

@onready var semi_abierta = $semi6
@onready var puerta_abierta = $puerta_abierta6
@onready var area = $Area2D6

var jugador_en_area = false
var jugador_ref: Node2D = null
var teletransportando = false  # Evita doble teletransporte

func _ready():
	# Estado inicial
	semi_abierta.visible = false
	puerta_abierta.visible = false
	
	# Conectar señales correctamente
	area.body_entered.connect(Callable(self, "_on_body_entered"))
	area.body_exited.connect(Callable(self, "_on_body_exited"))

# 🧍 Cuando el jugador entra al área
func _on_body_entered(body):
	if body.name == "Player2" or body.name == "player2":
		jugador_en_area = true
		jugador_ref = body
		animar_apertura()

# 🚶 Cuando el jugador sale del área
func _on_body_exited(body):
	if body == jugador_ref:
		jugador_en_area = false
		jugador_ref = null
		cerrar_puerta()

# 🎬 Animación de apertura
func animar_apertura():
	if teletransportando:
		return
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

# 🕹️ Detectar acción de teletransporte
func _process(_delta):
	if jugador_en_area and not teletransportando and Input.is_action_just_pressed("ui_up"):
		teletransportando = true
		await teletransportar_jugador()
		teletransportando = false

# ✨ Teletransportar jugador
func teletransportar_jugador():
	if not jugador_ref:
		push_warning("⚠️ No hay jugador asignado.")
		return
	if not destino:
		push_warning("⚠️ No hay destino asignado para esta puerta.")
		return

	print("⏳ Teletransportando jugador...")
	await get_tree().create_timer(0.2).timeout

	if jugador_ref and destino:
		jugador_ref.global_position = destino.global_position
		print("🚀 Jugador teletransportado a", destino.name)
	else:
		push_warning("⚠️ Error durante el teletransporte.")

	cerrar_puerta()
