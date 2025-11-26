extends Area2D

@onready var anim = $Sprite2D   # <- usa el nombre REAL del nodo
@onready var hackerm = $hackerm


func _ready():
	anim.play("idle")
	visible = true
	print("HackerM activo:", self.name)
