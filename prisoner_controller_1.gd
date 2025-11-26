extends Node

# Sistema de control de prisioneros para Lab2 - Solo Prisoner1 y Prisoner2
@export var spawn_interval: float = 20.0  # Cada cuánto aparece un prisionero
@export var prisoner_lifetime: float = 8.0  # Duración de cada prisionero activo

var prisoner1 = null
var prisoner2 = null
var active_prisoner = null
var spawn_timer: Timer
var use_prisoner1_next = true  # Alternar entre los dos

# Referencia al nodo principal del mapa
var lab2_node = null

func _ready():
	print("\n👮 Inicializando sistema de prisioneros (Solo 1 y 2)...")
	
	# Obtener referencia al nodo Lab2 (el padre)
	lab2_node = get_parent()
	
	# Esperar un frame para asegurar que toda la escena esté cargada
	await get_tree().process_frame
	
	# Buscar específicamente Prisoner1 y Prisoner2
	_find_specific_prisoners()
	
	# Desactivar ambos al inicio
	if prisoner1:
		_deactivate_prisoner(prisoner1)
	if prisoner2:
		_deactivate_prisoner(prisoner2)
	
	# Configurar timer de spawn
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_next_prisoner)
	add_child(spawn_timer)
	
	# Esperar un poco antes de empezar los spawns
	await get_tree().create_timer(5.0).timeout
	spawn_timer.start()
	
	# Activar el primero después de 5 segundos
	_spawn_next_prisoner()

func _find_specific_prisoners():
	# Buscar específicamente por nombre
	var root = get_tree().current_scene
	
	# Buscar Prisoner1 (o prisoner1, Prisionero1, prisionero1)
	prisoner1 = root.get_node_or_null("Prisoner11")
	if not prisoner1:
		prisoner1 = root.get_node_or_null("prisoner11")
	if not prisoner1:
		prisoner1 = root.get_node_or_null("Prisionero11")
	if not prisoner1:
		prisoner1 = root.get_node_or_null("prisionero11")
	
	# Buscar Prisoner2 (o prisoner2, Prisionero2, prisionero2)
	prisoner2 = root.get_node_or_null("Prisoner22")
	if not prisoner2:
		prisoner2 = root.get_node_or_null("prisoner22")
	if not prisoner2:
		prisoner2 = root.get_node_or_null("Prisionero22")
	if not prisoner2:
		prisoner2 = root.get_node_or_null("prisionero22")
	
	# Verificar y añadir al grupo
	if prisoner1:
		prisoner1.add_to_group("prisoners")
		print("  ✅ Prisoner1 encontrado:", prisoner1.name)
	else:
		print("  ❌ No se encontró Prisoner11")
		
	if prisoner2:
		prisoner2.add_to_group("prisoners")
		print("  ✅ Prisoner2 encontrado:", prisoner2.name)
	else:
		print("  ❌ No se encontró Prisoner22")

func _spawn_next_prisoner():
	# No spawnar si hay un minijuego en progreso
	if lab2_node and lab2_node.get("minijuego_en_progreso"):
		print("  ⏸️ Minijuego en progreso, esperando...")
		return
	
	# Si hay uno activo, desactivarlo primero
	if active_prisoner:
		_deactivate_prisoner(active_prisoner)
		active_prisoner = null
	
	# Alternar entre prisoner1 y prisoner2
	if use_prisoner1_next:
		if prisoner1:
			active_prisoner = prisoner1
			use_prisoner1_next = false
		elif prisoner2:
			active_prisoner = prisoner2
			use_prisoner1_next = true
		else:
			print("  ❌ Ningún prisionero disponible")
			return
	else:
		if prisoner2:
			active_prisoner = prisoner2
			use_prisoner1_next = true
		elif prisoner1:
			active_prisoner = prisoner1
			use_prisoner1_next = false
		else:
			print("  ❌ Ningún prisionero disponible")
			return
	
	print("\n👮 Activando:", active_prisoner.name)
	
	# Activar el prisionero
	_activate_prisoner(active_prisoner)
	
	# Programar desactivación
	await get_tree().create_timer(prisoner_lifetime).timeout
	if active_prisoner:
		print("  ⏰ Tiempo terminado para:", active_prisoner.name)
		_deactivate_prisoner(active_prisoner)
		active_prisoner = null

func _activate_prisoner(prisoner):
	if not prisoner:
		return
	
	# Hacer visible
	prisoner.visible = true
	
	# Si es Area2D
	if prisoner is Area2D:
		prisoner.monitoring = true
		prisoner.monitorable = true
	
	# Activar procesos
	prisoner.set_process(true)
	prisoner.set_physics_process(true)
	
	# Activar colisiones
	for child in prisoner.get_children():
		if child is CollisionShape2D:
			child.disabled = false
	
	# Si tiene método activate
	if prisoner.has_method("activate"):
		prisoner.activate()

func _deactivate_prisoner(prisoner):
	if not prisoner:
		return
	
	# Si tiene método deactivate
	if prisoner.has_method("deactivate"):
		prisoner.deactivate()
	
	# Hacer invisible
	prisoner.visible = false
	
	# Si es Area2D
	if prisoner is Area2D:
		prisoner.monitoring = false
		prisoner.monitorable = false
	
	# Desactivar procesos
	prisoner.set_process(false)
	prisoner.set_physics_process(false)
	
	# Desactivar colisiones
	for child in prisoner.get_children():
		if child is CollisionShape2D:
			child.disabled = true

func pause_prisoners():
	print("⏸ Pausando prisioneros por minijuego")
	spawn_timer.paused = true
	
	# Pausar TODOS los prisioneros, no solo el activo
	for p in get_tree().get_nodes_in_group("prisoners"):
		if p.has_method("pause"):
			p.pause()


func resume_prisoners():
	print("▶ Reanudando prisioneros")
	spawn_timer.paused = false
	
	for p in get_tree().get_nodes_in_group("prisoners"):
		if p.has_method("resume"):
			p.resume()
