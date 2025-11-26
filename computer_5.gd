extends Area2D

signal interactuar

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	set_process_input(false)

var player_cerca = false

func _on_body_entered(body):
	if body.name == "Player1":
		player_cerca = true
		set_process_input(true)
		print(" El jugador puede interactuar")

func _on_body_exited(body):
	if body.name == "Player1":
		player_cerca = false
		set_process_input(false)
		print(" El jugador se alejó")

func _input(event):
	if player_cerca and event.is_action_pressed("interactuar"):
		print("Interactuando con el computador")
		emit_signal("interactuar")
