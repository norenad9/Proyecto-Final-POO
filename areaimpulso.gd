extends Area2D

@export var fuerza_impulso: float = -400.0  # fuerza hacia arriba (negativo = arriba)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

# Cuando un cuerpo entra en el área
func _on_body_entered(body):
	# Asegurarnos que sea un CharacterBody2D (tu jugador)
	if body is CharacterBody2D:
		# Aplicar el impulso vertical directamente
		body.velocity.y = fuerza_impulso
		# Si el jugador tiene la variable 'en_impulso', activarla
		if "en_impulso" in body:
			body.en_impulso = true
		print(" Jugador impulsado hacia arriba con fuerza:", fuerza_impulso)

# Cuando un cuerpo sale del área
func _on_body_exited(body):
	if body is CharacterBody2D:
		if "en_impulso" in body:
			body.en_impulso = false
		print("Jugador salió del área de impulso")
