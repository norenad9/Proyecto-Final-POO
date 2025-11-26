extends Node2D

@export var destino: Node2D  # 👈 cada puerta tendrá su destino propio asignado desde el editor

@onready var puerta_abierta = $puerta_abierta1
@onready var area = $Area2D1
@onready var animation_player = $AnimationPlayer

var jugador_en_area = false
var jugador_ref = null

func _ready():
	puerta_abierta.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		jugador_en_area = true
		jugador_ref = body

func _on_body_exited(body):
	if body == jugador_ref:
		jugador_en_area = false
		jugador_ref = null
		cerrar_puerta()

func _process(delta):
	if jugador_en_area and Input.is_action_just_pressed("ui_up"):
		abrir_y_teletransportar()

func abrir_y_teletransportar():
	# Mostrar puerta abierta
	puerta_abierta.visible = true
	if animation_player:
		animation_player.play("abrir")
	print("🚪 Puerta abierta")

	# Teletransportar inmediatamente (con pequeño retardo opcional)
	if jugador_ref and destino:
		await get_tree().create_timer(0.2).timeout  # ⏳ delay opcional para ver la animación
		jugador_ref.global_position = destino.global_position
		print("Jugador teletransportado 🚀 a", destino.name)
		cerrar_puerta()

func cerrar_puerta():
	puerta_abierta.visible = false
	if animation_player:
		animation_player.play("cerrar")
	print("🚪 Puerta cerrada")
