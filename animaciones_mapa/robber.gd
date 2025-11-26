extends Area2D

@onready var anim = $Sprite2D   # <- usa el nombre REAL del nodo

func _ready():
	anim.play("idle")
	visible = true
	print("Robber activo:", self.name)
