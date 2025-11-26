extends Area2D

signal interactuar

var is_blocked: bool = false
var player_cerca: bool = false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	set_process_input(false)

func _on_body_entered(body):
	if body.is_in_group("jugador"):
		player_cerca = true
		set_process_input(true)
		print("🟢 Jugador cerca de", name)

func _on_body_exited(body):
	if body.is_in_group("jugador"):
		player_cerca = false
		set_process_input(false)
		print("🔴 Jugador se alejó de", name)

func _input(event):
	if player_cerca and event.is_action_pressed("interactuar"):
		if is_blocked:
			print("⛔ Minijuego bloqueado por Robber en", name)
			return
		print("🖥 Interactuando con", name)
		emit_signal("interactuar")
func hack_damage():
	is_blocked = true
	print("💥 COMPUTADORA HACKEADA:", name)

	# Si tienes icono de alerta
	var icon = get_node_or_null("icon_alerta")
	if icon:
		icon.visible = true
