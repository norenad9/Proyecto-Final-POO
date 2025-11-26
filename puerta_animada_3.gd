extends Node2D

@export var destino: Node2D  # 👈 asigna esto desde el editor

@onready var puerta_abierta = $puerta_abierta3
@onready var area = $Area2D3
@onready var animation_player = $AnimationPlayer

var jugador_en_area = false
var jugador_ref: Node2D = null

func _ready():
	puerta_abierta.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		jugador_en_area = true
		jugador_ref = body
		print("👤 Jugador entró al área de la puerta 3")

func _on_body_exited(body):
	if body == jugador_ref:
		jugador_en_area = false
		jugador_ref = null
		cerrar_puerta()
		print("👤 Jugador salió del área de la puerta 3")

func _process(delta):
	if jugador_en_area and Input.is_action_just_pressed("ui_up"):
		abrir_y_teletransportar()

func abrir_y_teletransportar():
	# Validaciones
	if not jugador_ref:
		push_warning("⚠️ No hay jugador asignado, no se puede teletransportar.")
		return
	if not destino:
		push_warning("⚠️ No hay destino asignado en el editor para esta puerta.")
		return

	# Mostrar puerta abierta
	puerta_abierta.visible = true
	if animation_player:
		animation_player.play("abrir")
	print("🚪 Puerta 3 abierta")

	# Teletransportar después de un pequeño delay (para ver la animación)
	await get_tree().create_timer(0.2).timeout  # ⏳ pequeño retardo visual

	# Teletransporte seguro
	if jugador_ref and destino:
		jugador_ref.global_position = destino.global_position
		print("🚀 Jugador teletransportado a:", destino.name)
	else:
		push_warning("⚠️ Error: jugador o destino no válidos durante el teletransporte.")

	cerrar_puerta()

func cerrar_puerta():
	puerta_abierta.visible = false
	if animation_player:
		animation_player.play("cerrar")
	print("🚪 Puerta 3 cerrada")
