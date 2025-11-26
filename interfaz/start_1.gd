extends TextureRect

var start_normal = "res://interfaz/start1.png"
var start_hover = "res://interfaz/start2.png"

@onready var hover_area = $"../HoverArea"  # 👈 Asegúrate de tener un Area2D llamado HoverArea junto al botón
@onready var selec=$"../../efectoSeleccion"

func _ready():
	texture = load(start_normal)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # El TextureRect ya no bloquea el mouse

	# Conectamos las señales del área invisible
	if hover_area:
		hover_area.mouse_entered.connect(_on_hover_entered)
		hover_area.mouse_exited.connect(_on_hover_exited)
		hover_area.input_event.connect(_on_hover_area_input)  # 👈 detecta click dentro del área
	else:
		push_error("⚠️ No se encontró el nodo HoverArea. Crea un Area2D con ese nombre al lado del botón.")

# 💡 Cuando el cursor entra al área invisible
func _on_hover_entered():
	texture = load(start_hover)

# 💡 Cuando el cursor sale del área invisible
func _on_hover_exited():
	texture = load(start_normal)

# 🖱️ Detectar click dentro del área invisible
func _on_hover_area_input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		print("Click en Start!")
		show_select_screen()

# 🚀 Cambiar a la pantalla de selección
func show_select_screen():
	self.visible = false
	var select = get_parent().get_node_or_null("selectc")  # 👈 cambia el nombre si tu nodo se llama diferente
	if select:
		selec.play()
		select.visible = true
	else:
		push_error("❌ No se encontró el nodo 'selectc'. Verifica que esté dentro del mismo CanvasLayer.")
