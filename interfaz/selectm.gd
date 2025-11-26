extends Control
@onready var selec=$"../../efectoSeleccion"

func _ready():
	# Conectar los nodos lab1, lab2 y lab3
	for name in ["lab1b", "lab2b", "lab3b"]:
		var lab = get_node_or_null(name)
		if lab:
			lab.connect("mouse_entered", Callable(self, "_on_lab_hovered").bind(name))
			lab.connect("mouse_exited", Callable(self, "_on_lab_exited"))
			lab.connect("gui_input", Callable(self, "_on_lab_clicked").bind(name))
			print("✅ Conectado:", name)
		else:
			print("⚠️ No se encontró el nodo:", name)


# 🖼️ Mostrar preview del mapa al pasar el mouse
func _on_lab_hovered(lab_name: String):
	var mapa_path = ""
	match lab_name:
		"lab1b": mapa_path = "res://interfaz/mapa1.png"
		"lab2b": mapa_path = "res://interfaz/mapa2.png"
		"lab3b": mapa_path = "res://interfaz/mapa3.png"

	if mapa_path != "":
		$preview.texture = load(mapa_path)
		print("🖼 Mostrando preview de", lab_name)


# ❌ Quitar preview al salir del botón
func _on_lab_exited():
	$preview.texture = null


# 🚪 Entrar a la escena correspondiente al hacer clic
func _on_lab_clicked(event: InputEvent, lab_name: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selec.play()
		print("🚪 Entrando a", lab_name)

		match lab_name:
			"lab1b":
				print("🔄 Cargando escena Lab1...")
				get_tree().change_scene_to_file("res://animaciones_mapa/lab1.tscn")

			"lab2b":
				print("🔄 Cargando escena Lab_2...")
				get_tree().change_scene_to_file("res://lab_2.tscn")

			"lab3b":
				get_tree().change_scene_to_file("res://lab_3.tscn")
