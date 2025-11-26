extends Control

@onready var escenas = [
	$escena1,
	$escena2,
	$escena3,
	$escena4,
	$escena5,
	$escena6
]
@onready var subtitulo = $subtitulo
@onready var skip_button = $skip_button
@onready var fade = $fade

var textos = [
	"Year 2247. Aboard the ISS Protector, everything seems normal...",
	"An intruder has infiltrated the ship...",
	"Warning! Unauthorized access detected. Main system compromised!",
	"Crew offline. You’re the last one left to fight back.",
	"Access the three cyberlabs to restore full control of the ship.",
	"Complete all tasks. Reboot the system. Save the ship."
]

var indice_actual = 0
var escribiendo = false
var saltando = false

var primera_escena = true   # 🔥 Solo la primera tendrá fade

func _ready():
	var fuente = load("res://PressStart2P-Regular.ttf")

	# Botón SKIP
	skip_button.text = "SKIP ▶"
	skip_button.add_theme_color_override("font_color", Color.WHITE)
	skip_button.add_theme_font_size_override("font_size", 32)
	skip_button.add_theme_font_override("font", fuente)
	skip_button.connect("pressed", Callable(self, "_on_skip_pressed"))

	# Configurar subtítulos
	subtitulo.add_theme_color_override("font_color", Color.WHITE)
	subtitulo.add_theme_font_size_override("font_size", 40)
	subtitulo.add_theme_font_override("font", fuente)

	# Ocultar todas las escenas excepto la primera
	for i in range(escenas.size()):
		escenas[i].visible = (i == 0)

	await _fade_in_suave()   # 🔥 Fade solo para imagen inicial
	_mostrar_escena(indice_actual)


func _mostrar_escena(i):
	if saltando:
		return

	if i >= escenas.size():
		_finalizar_historia()
		return

	# --- Transición ---
	if primera_escena:
		# Después de usar fade una vez, apagamos comportamiento
		primera_escena = false
	else:
		# Sin fade: cambio instantáneo
		fade.modulate.a = 0.0

	# Cambiar visible la escena correspondiente
	for j in range(escenas.size()):
		escenas[j].visible = (j == i)

	subtitulo.text = ""
	await _escribir_texto(textos[i])

	await get_tree().create_timer(2.5).timeout
	indice_actual += 1
	_mostrar_escena(indice_actual)


# --- Efecto de escritura ---
func _escribir_texto(texto: String):
	escribiendo = true
	subtitulo.text = ""

	for i in range(texto.length()):
		if saltando:
			break
		subtitulo.text = texto.substr(0, i + 1)
		await get_tree().create_timer(0.03).timeout

	escribiendo = false


# --- Fade suave SOLO para escena 1 ---
func _fade_in_suave():
	fade.modulate.a = 0.7
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 1.2)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	await tween.finished


# --- Skip button ---
func _on_skip_pressed():
	saltando = true
	escribiendo = false

	var tween = create_tween()
	tween.tween_property(skip_button, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(skip_button, "scale", Vector2(1.0, 1.0), 0.08)
	await get_tree().create_timer(0.1).timeout

	get_tree().change_scene_to_file("res://interfaz/menu.tscn")


func _process(delta):
	if skip_button.get_rect().has_point(get_local_mouse_position()):
		skip_button.add_theme_color_override("font_color", Color(0.2, 1.0, 0.8))
	else:
		skip_button.add_theme_color_override("font_color", Color.WHITE)


func _finalizar_historia():
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://interfaz/menu.tscn")
