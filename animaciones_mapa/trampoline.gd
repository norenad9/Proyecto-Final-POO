extends Node2D

@export var fuerza_rebote: float = 550.0   # fuerza del salto
@export var tiempo_animacion: float = 0.1  # duración entre fases

@onready var fase1 = $fase1
@onready var fase2 = $fase2
@onready var fase3 = $fase3
@onready var area = $Area2D   # asegúrate que tu Area2D se llame así

var rebotando = false

func _ready():
	fase1.visible = true
	fase2.visible = false
	fase3.visible = false
	
	if area:
		area.connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# Solo si es jugador y no está rebotando
	if body.is_in_group("jugador") and not rebotando:
		rebotando = true

		# Animación del trampolín
		fase1.visible = false
		fase2.visible = true

		# Aplicar impulso al jugador
		if body.has_method("aplicar_rebote"):
			body.aplicar_rebote(fuerza_rebote)

		# Secuencia visual de rebote
		await get_tree().create_timer(tiempo_animacion).timeout
		fase2.visible = false
		fase3.visible = true

		await get_tree().create_timer(tiempo_animacion).timeout
		fase3.visible = false
		fase1.visible = true

		rebotando = false
