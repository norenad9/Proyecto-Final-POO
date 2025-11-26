extends AnimatableBody2D

@export var velocidad: float = 100.0
@export var distancia: float = 80.0
@export var pausa: float = 0.5

@onready var colision_repisa = $colisionrepisa1
@onready var colision_piso = $colisionpiso1

var direccion = -1
var punto_inicial_y = 0.0
var pausando = false

func _ready():
	punto_inicial_y = global_position.y

func _physics_process(delta):
	if pausando:
		return

	# Movimiento vertical controlado
	global_position.y += velocidad * direccion * delta

	# Límite superior e inferior
	if global_position.y <= punto_inicial_y - distancia and direccion == -1:
		await detener_y_reversar()
	elif global_position.y >= punto_inicial_y + distancia and direccion == 1:
		await detener_y_reversar()

func detener_y_reversar():
	pausando = true
	await get_tree().create_timer(pausa).timeout
	direccion *= -1
	pausando = false
