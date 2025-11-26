extends Node2D

@export var fuerza_rebote: float = 570.0   # fuerza del salto
@export var repisa: Node2D                  # opcional: si el trampolín está sobre una repisa móvil
@export var offset := Vector2(0, 0)

@onready var fase1 = $fase1
@onready var fase2 = $fase2
@onready var fase3 = $fase3
@onready var area = $Area2D

var rebotando = false

func _ready():
	fase1.visible = true
	fase2.visible = false
	fase3.visible = false
	area.connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(_delta):
	# Si tiene repisa, sigue su posición
	if repisa:
		global_position = repisa.global_position + offset

func _on_body_entered(body):
	# Solo reacciona si es el jugador y no está en animación de rebote
	if body.is_in_group("jugador") and not rebotando:
		rebotando = true

		# Cambiar sprites (animación simple del trampolín)
		fase1.visible = false
		fase2.visible = true

		# Aplicar impulso al jugador
		if body.has_method("aplicar_rebote"):
			body.aplicar_rebote(fuerza_rebote)

		# Esperar un momento y mostrar fase3 (extendido)
		await get_tree().create_timer(0.1).timeout
		fase2.visible = false
		fase3.visible = true

		# Luego volver a fase1 (reposo)
		await get_tree().create_timer(0.1).timeout
		fase3.visible = false
		fase1.visible = true

		rebotando = false
