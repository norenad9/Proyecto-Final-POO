extends Control

# Diccionario con rutas de escenas (para cuando empiece el juego)
var characters = {
	"agentep": "res://agentep.tscn",
	"agentex": "res://agentex.tscn",
	"agentez": "res://agentez.tscn"
}

var selected_scene_path: String = ""

@onready var foco1 = $foco1
@onready var foco2 = $foco2
@onready var foco3 = $foco3
@onready var selec=$"../../efectoSeleccion"

func _ready():
	# Activar animaciones de todos los personajes al iniciar selectc
	for agent_name in characters.keys():
		var sprite = get_node_or_null(agent_name + "/AnimatedSprite2D")
		if sprite:
			sprite.play("breath")
			print("🎞 Animación 'breath' activada en", agent_name)
		else:
			print("⚠️ No se encontró AnimatedSprite2D en", agent_name)

	# Conectar las áreas de cada agente
	_connect_agent_area("agentep", "Areap")
	_connect_agent_area("agentex", "Areax")
	_connect_agent_area("agentez", "Areaz")

	# Apagar todos los focos al inicio
	_apagar_todos_focos()


func _connect_agent_area(agent_name: String, area_name: String):
	var agent = get_node_or_null(agent_name)
	if agent:
		var area = agent.get_node_or_null(area_name)
		if area:
			# Hover (pasa el cursor)
			area.connect("mouse_entered", Callable(self, "_on_agent_hovered").bind(agent_name))
			area.connect("mouse_exited", Callable(self, "_on_agent_unhovered").bind(agent_name))
			# Click (selección)
			area.connect("input_event", Callable(self, "_on_agent_clicked").bind(agent_name))
			print("✅ Conectadas señales hover y click de", area_name, "en", agent_name)
		else:
			print("⚠️ No se encontró el área:", area_name)
	else:
		print("⚠️ No se encontró el nodo del agente:", agent_name)


# 🔦 Control de focos
func _apagar_todos_focos():
	foco1.get_node("f1").visible = true
	foco1.get_node("f2").visible = false
	foco2.get_node("f1").visible = true
	foco2.get_node("f2").visible = false
	foco3.get_node("f1").visible = true
	foco3.get_node("f2").visible = false

func _encender_foco(foco: Node):
	_apagar_todos_focos()
	foco.get_node("f1").visible = false
	foco.get_node("f2").visible = true


# 💡 Cuando el cursor entra/sale del área
func _on_agent_hovered(agent_name: String):
	match agent_name:
		"agentep":
			_encender_foco(foco1)
		"agentex":
			_encender_foco(foco2)
		"agentez":
			_encender_foco(foco3)
	print("💡 Cursor sobre:", agent_name)

func _on_agent_unhovered(agent_name: String):
	_apagar_todos_focos()
	print("⬛ Cursor salió de:", agent_name)


# 🖱️ Cuando se hace clic en un agente (igual que antes)
func _on_agent_clicked(_viewport, event: InputEvent, _shape_idx: int, agent_name: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selec.play()
		selected_scene_path = characters[agent_name]
		print("🧩 Personaje seleccionado:", agent_name)

		# Guardar selección global en GameManager
		var gm = get_node("/root/GameManager")
		gm.selected_character = agent_name
		print("💾 Guardado en GameManager:", gm.selected_character)

		# Mostrar selectm y ocultar selectc
		var selectm = get_node("../selectm")
		selectm.visible = true
		visible = false

		# Duplicar el AnimatedSprite2D del agente seleccionado
		var source_sprite = get_node(agent_name + "/AnimatedSprite2D")
		if source_sprite:
			var cloned_sprite = source_sprite.duplicate()
			cloned_sprite.play("breath")

			var character_rect = selectm.get_node_or_null("character")
			if character_rect:
				for c in character_rect.get_children():
					c.queue_free()

				character_rect.add_child(cloned_sprite)
				cloned_sprite.position = character_rect.size / 2
				print("✅ Sprite de", agent_name, "copiado dentro de 'character' en selectm")
			else:
				print("⚠️ No se encontró el TextureRect 'character' en selectm")
		else:
			print("⚠️ No se encontró AnimatedSprite2D en", agent_name)
