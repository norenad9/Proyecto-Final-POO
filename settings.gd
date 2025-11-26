extends Control

@onready var escenas = [
	$escena1,
	$escena2,
	$escena3,
	$escena4,
	$escena5,
	$escena6
]

@onready var next_button = $next_button
@onready var back_button = $back_button
@onready var fade = $fade
@onready var music = $AudioStreamPlayer

var indice_actual = 0


func _ready():
	music.play()
	var fuente = load("res://PressStart2P-Regular.ttf")

	# ---- Configurar NEXT ----
	next_button.text = "NEXT ▶"
	next_button.add_theme_font_override("font", fuente)
	next_button.add_theme_font_size_override("font_size", 32)
	next_button.connect("pressed", Callable(self, "_on_next_pressed"))
	next_button.connect("mouse_entered", Callable(self, "_on_next_hover"))
	next_button.connect("mouse_exited", Callable(self, "_on_next_leave"))
	next_button.connect("button_down", Callable(self, "_on_next_pressed_effect"))

	# ---- Configurar BACK ----
	back_button.text = "◀ BACK"
	back_button.add_theme_font_override("font", fuente)
	back_button.add_theme_font_size_override("font_size", 32)
	back_button.visible = false
	back_button.connect("pressed", Callable(self, "_on_back_pressed"))
	back_button.connect("mouse_entered", Callable(self, "_on_back_hover"))
	back_button.connect("mouse_exited", Callable(self, "_on_back_leave"))
	back_button.connect("button_down", Callable(self, "_on_back_pressed_effect"))

	# ---- Ocultar escenas excepto primera ----
	for i in range(escenas.size()):
		escenas[i].visible = (i == 0)

	await _fade_in_suave()

func _on_next_pressed():
	await _fade_out_suave()

	indice_actual += 1

	if indice_actual >= escenas.size():
		_finalizar_historia()
		return

	for i in range(escenas.size()):
		escenas[i].visible = (i == indice_actual)

	await _fade_in_suave()

	if indice_actual == escenas.size() - 1:
		next_button.visible = false
		back_button.visible = true

func _on_back_pressed():
	await _fade_out_suave()
	get_tree().change_scene_to_file("res://interfaz/menu.tscn")
	
func _fade_in_suave():
	fade.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.8)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	await tween.finished

func _fade_out_suave():
	fade.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.6)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	await tween.finished
func _on_next_hover():
	next_button.modulate = Color(0.8, 0.8, 0.8)

func _on_next_leave():
	next_button.modulate = Color(1, 1, 1)

func _on_next_pressed_effect():
	next_button.scale = Vector2(0.9, 0.9)
	await get_tree().create_timer(0.08).timeout
	next_button.scale = Vector2(1, 1)


func _on_back_hover():
	back_button.modulate = Color(0.8, 0.8, 0.8)

func _on_back_leave():
	back_button.modulate = Color(1, 1, 1)

func _on_back_pressed_effect():
	back_button.scale = Vector2(0.9, 0.9)
	await get_tree().create_timer(0.08).timeout
	back_button.scale = Vector2(1, 1)
func _finalizar_historia():
	print("Historia completada. flechai activa.")
