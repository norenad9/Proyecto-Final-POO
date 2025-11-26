extends TextureRect

var original_modulate: Color
var tween: Tween

func _ready():
	original_modulate = modulate
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tween = create_tween()

func _on_mouse_entered():
	tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.6, 0.6, 0.6, 1.0), 0.15)

func _on_mouse_exited():
	tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.15)
