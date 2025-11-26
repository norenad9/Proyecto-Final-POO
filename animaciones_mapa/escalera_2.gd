extends Area2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body is CharacterBody2D:
		body.en_escalera = true
		print("🪜 Jugador tocó la escalera")

func _on_body_exited(body):
	if body is CharacterBody2D:
		body.en_escalera = false
		body.subiendo = false
		print("🚶‍♂️ Jugador salió de la escalera")
