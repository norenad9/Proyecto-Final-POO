extends CanvasLayer

@onready var button_settings = $ButtonSettings
@onready var button_exit = $ButtonExit

var fuente := preload("res://PressStart2P-Regular.ttf")

func _ready():
	# ===== Estilo de letra para SETTINGS =====
	button_settings.add_theme_font_override("font", fuente)
	button_settings.add_theme_font_size_override("font_size", 28)

	# ===== Estilo de letra para EXIT =====
	button_exit.add_theme_font_override("font", fuente)
	button_exit.add_theme_font_size_override("font_size", 28)

	# ===== Conectar acciones =====
	button_settings.connect("pressed", Callable(self, "_on_settings_pressed"))
	button_exit.connect("pressed", Callable(self, "_on_exit_pressed"))

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://settings.tscn")

func _on_exit_pressed():
	get_tree().quit()
