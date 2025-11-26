extends TextureRect

# Texturas de la flecha
var normal_texture = load("res://interfaz/flecha.png")
var hover_texture = load("res://interfaz/flechahover.png")

@onready var flecha_area = $flechahover  # 👈 tu área 2D
@onready var efecto = $"../../../efectoSeleccion"
func _ready():
	texture = normal_texture
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # dejamos que el área maneje el mouse
	visible = true

	# Conectar señales del área
	flecha_area.mouse_entered.connect(_on_area_mouse_entered)
	flecha_area.mouse_exited.connect(_on_area_mouse_exited)
	flecha_area.input_event.connect(_on_area_input_event)

	print("✅ Flecha lista en selectc con área de hover")

# 🖱️ Cuando el cursor entra al área
func _on_area_mouse_entered():
	if hover_texture:
		texture = hover_texture

# 🖱️ Cuando el cursor sale del área
func _on_area_mouse_exited():
	texture = normal_texture

# 👆 Detectar click dentro del área
func _on_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("↩ Volviendo a la interfaz desde flechahover...")
		efecto.play()
		show_interface()

# 🔁 Volver a la interfaz anterior
func show_interface():
	var canvas_layer = get_parent().get_parent()

	if canvas_layer:
		var interface = canvas_layer.get_node_or_null("interface")
		var start1 = canvas_layer.get_node_or_null("start1")
		var selectc = canvas_layer.get_node_or_null("selectc")

		if interface:
			interface.visible = true
			print("✅ Interface visible")
		else:
			print("⚠️ No se encontró 'interface'")

		if start1:
			start1.visible = true
			print("✅ Start visible")
		else:
			print("⚠️ No se encontró 'start1'")

		if selectc:
			selectc.visible = false
	else:
		print("⚠️ No se encontró CanvasLayer")


func _on_mouse_entered() -> void:
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	pass # Replace with function body.
