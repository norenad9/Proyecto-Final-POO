extends TextureRect

# 🖼️ Texturas
var normal_texture = load("res://interfaz/flecha.png")
var hover_texture = load("res://interfaz/flechahover.png")  # imagen que aparece al pasar el mouse

@onready var flecha_area: Area2D = $flechaahover  # 👈 tu nodo Area2D (padre del CollisionShape2D)

func _ready():
	texture = normal_texture
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # el área capta el mouse, no el TextureRect
	visible = true

	# 🔗 Conectamos las señales del área
	if flecha_area:
		flecha_area.connect("mouse_entered", Callable(self, "_on_area_mouse_entered"))
		flecha_area.connect("mouse_exited", Callable(self, "_on_area_mouse_exited"))
		flecha_area.connect("input_event", Callable(self, "_on_area_input_event"))
		print("✅ Flecha lista con área flechaahover")
	else:
		push_error("⚠️ No se encontró el nodo 'flechaahover'. Debe ser hijo del TextureRect.")

# 🖱️ Cuando el cursor entra en el CollisionShape2D
func _on_area_mouse_entered():
	if hover_texture:
		texture = hover_texture
		print("🖱️ Cursor sobre la flecha (hover)")

# 🖱️ Cuando el cursor sale del CollisionShape2D
func _on_area_mouse_exited():
	texture = normal_texture
	print("💨 Cursor salió de la flecha")

# 👆 Detectar click dentro del área (CollisionShape2D)
func _on_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("↩ Click en flecha → volver a SelectC")
		show_selectc()

# 🔁 Cambiar de pantalla: SelectM → SelectC
func show_selectc():
	var canvas_layer = get_parent().get_parent()

	if canvas_layer:
		var selectc = canvas_layer.get_node_or_null("selectc")
		var selectm = canvas_layer.get_node_or_null("selectm")

		if selectc:
			selectc.visible = true
			print("✅ Mostrando SelectC")
		else:
			print("⚠️ No se encontró 'selectc'")

		if selectm:
			selectm.visible = false
	else:
		print("⚠️ No se encontró CanvasLayer")
