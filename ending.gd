extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	# Crear el Label para los subtítulos
	var label = Label.new()
	label.name = "VictoryText"
	label.add_theme_font_override("font", load("res://PressStart2P-Regular.ttf"))
	label.add_theme_font_size_override("font_size", 35)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Centrar el texto en la pantalla
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.position = Vector2(50,70)
	label.pivot_offset = label.size / 2
	
	# Agregar el label a la escena
	add_child(label)
	
	# Iniciar la animación de escritura
	_typewriter_effect(label, "Congratulations! You have won!")
	
	# Esperar 10 segundos y cambiar al menú
	await get_tree().create_timer(10.0).timeout
	get_tree().change_scene_to_file("res://interfaz/menu.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Función para el efecto de máquina de escribir
func _typewriter_effect(label: Label, text: String) -> void:
	label.text = ""
	label.visible = true
	
	for i in range(text.length()):
		label.text += text[i]
		await get_tree().create_timer(0.1).timeout  # Velocidad de escritura
