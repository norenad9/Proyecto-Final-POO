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
	if body.name == "Player1" or body.is_in_group("player1"):
		jugador_en_area = true
		jugador_ref = body
		print("👤 Jugador detectado en el área de la puerta")

func _on_body_exited(body):
	if body == jugador_ref:
		jugador_en_area = false
		jugador_ref = null
		cerrar_puerta()

func _process(delta):
	if jugador_en_area and Input.is_action_just_pressed("ui_up"):
		abrir_y_teletransportar()

func abrir_y_teletransportar():
	if not jugador_ref:
		push_warning("⚠️ No hay jugador asignado, no se puede teletransportar.")
		return
	if not destino:
		push_warning("⚠️ No hay destino asignado en el editor.")
		return

	# Mostrar puerta abierta y animación
	puerta_abierta.visible = true
	if animation_player:
		animation_player.play("abrir")
	print("🚪 Puerta abierta")

	# Esperar 0.2 segundos para efecto visual
	await get_tree().create_timer(0.2).timeout

	# Teletransportar jugador
	if jugador_ref and destino:
		jugador_ref.global_position = destino.global_position
		print("🚀 Jugador teletransportado a:", destino.name)
		cerrar_puerta()
	else:
		push_warning("⚠️ Error: jugador o destino no válidos durante teletransporte.")

func cerrar_puerta():
	puerta_abierta.visible = false
	if animation_player:
		animation_player.play("cerrar")
	print("🚪 Puerta cerrada")
