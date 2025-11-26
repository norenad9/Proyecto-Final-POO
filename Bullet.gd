extends Area2D

var velocity: Vector2 = Vector2.ZERO
var max_distance = 650  # píxeles
var distance_traveled = 0


func _ready():
	collision_layer = 4
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var move_amount = velocity * delta
	position += move_amount
	distance_traveled += move_amount.length()

	if distance_traveled >= max_distance:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		print("💥 Bala tocó cuerpo del PLAYER")
		body.take_damage()  # Llama directo al player
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("player"):
		print("💥 Bala tocó un HITBOX del Player (colisión)")
		area.get_parent().take_damage()
		queue_free()
