extends Node2D

# ============================================================
# VARIABLES
# ============================================================

var minijuego_actual: Node = null
var minijuego_en_progreso = false
var tiempo_extra_activo = false
var game_over_mostrado = false
var timer_extra_countdown = null
var shield_label: Label = null
var shield_active = false
var shield_recharging = false
# --------------- HACKER ----------------
var hacker_activado = false
@onready var hackerm = $hackerm
@onready var hacker = $hackerm   # Cambia la ruta si tu nodo no se llama así
@onready var audio = $AudioStreamPlayer


@onready var player = $Player2
@onready var computer = $Computer10
@onready var computer2 = $Computer11
@onready var computer3 = $Computer12
@onready var computer4 = $Computer13
@onready var computer5 = $Computer14

# ============================================================
#  INICIO
# ============================================================

# Arrays para almacenar robbers y mapeos
var robbers = []
var robber_to_computer = {}

# Registro de minijuegos completados
var minijuegos_completados = {}

# Registro para controlar si cada computadora ya tuvo su robber aparecer
var robbers_aparecidos = {}

# Control de tiempo entre spawns
var spawn_interval = 15.0
var next_spawn = 5.0  # Primer spawn más rápido

var total_minijuegos = 5

func _ready():
	audio.play()
	print("🌍 Cargando Lab3...")
	
	# IMPORTANTE: Agregar el jugador al grupo "jugador"
	if player:
		player.add_to_group("jugador")
		print(" Player agregado al grupo 'jugador'")
	else:
		print(" ERROR: No se encontró el Player")
	
	# Buscar y capturar TODOS los robbers de forma flexible
	buscar_todos_los_robbers()
	
	# Configurar personaje del jugador
	configurar_jugador()
	
	# Ocultar todos los robbers al inicio
	for r in robbers:
		if r:
			r.visible = false
	
	# Bloquear todas las computadoras al inicio
	for comp in [computer, computer2, computer3, computer4, computer5]:
		if comp:
			comp.is_blocked = true
			print(" Computadora bloqueada al inicio:", comp.name)
	
	# Inicializar diccionarios de estado
	minijuegos_completados = {
		computer: false,
		computer2: false,
		computer3: false,
		computer4: false,
		computer5: false
	}
	
	robbers_aparecidos = {
		computer: false,
		computer2: false,
		computer3: false,
		computer4: false,
		computer5: false
	}
	
	hacker.visible = false  # Oculto al inicio
	start_hacker_timer()


	# IMPORTANTE: Conectar las computadoras DESPUÉS de inicializar todo
	_conectar_computadores()
	
	# Verificar configuración de input
	verificar_configuracion_input()
	
	
	
	print(" Sistema inicializado correctamente")
	print(" Total robbers encontrados:", robbers.size())
	print(" Presiona E cerca de una computadora desbloqueada para jugar")
	
func start_hacker_timer():
	# Esperar 25 segundos antes de activar hacker
	await get_tree().create_timer(25.0).timeout
	activar_hacker()
	
func activar_hacker():
	if hackerm.visible:
		return  # Para que solo aparezca una vez

	# Mostrar hacker
	hackerm.visible = true
	print(" HACKERM APARECE – SISTEMA SABOTEADO")
	# ⏳ Hackerm dura solo 8 segundos
	await get_tree().create_timer(8.0).timeout
	print(" HACKERM SE RETIRA – SISTEMA RESTABLECIDO")

	hackerm.visible = false

	# SABOTEAR todas las computadoras, incluso reparadas
	for comp in [computer, computer2, computer3, computer4, computer5]:
		if comp:
			comp.hack_damage()  # Llamado al método del computer
			minijuegos_completados[comp] = false
			robbers_aparecidos[comp] = false
			comp.is_blocked = false  # Permitir interactuar
			print(" Computadora saboteada:", comp.name)

	# Mostrar mensaje visual
	mostrar_mensaje_hack()
	
func mostrar_mensaje_hack():
	var msg = Label.new()
	msg.text = " SYSTEM BREACHED – REPAIR ALL TERMINALS!"
	msg.add_theme_font_size_override("font_size", 60)
	msg.add_theme_color_override("font_color", Color.RED)
	msg.add_theme_color_override("font_shadow_color", Color.BLACK)
	msg.add_theme_constant_override("shadow_offset_x", 4)
	msg.add_theme_constant_override("shadow_offset_y", 4)

	var viewport_size = get_viewport().size
	msg.position = Vector2(viewport_size.x/2 - 700, 80)

	var ui_layer = get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(msg)
	else:
		add_child(msg)

	await get_tree().create_timer(3.5).timeout
	msg.queue_free()


	
	
func verificar_configuracion_input():
	print("\n🎮 Verificando configuración de controles:")
	if InputMap.has_action("interactuar"):
		print("  ✓ Acción 'interactuar' configurada")
		var events = InputMap.action_get_events("interactuar")
		for event in events:
			if event is InputEventKey:
				print("    Tecla:", event.as_text())
	else:
		print("   ERROR: No existe la acción 'interactuar' en el InputMap")
		print("   Ve a Project Settings > Input Map y agrega:")
		print("     - Nombre: interactuar")
		print("     - Tecla: E")
		
func _input(event):
	if event.is_action_pressed("shield") and not shield_active and not shield_recharging:
		activar_shield()

func activar_shield():
	shield_active = true
	shield_recharging = true

	print("SHIELD ACTIVATED")

	crear_label_shield()

	# ---- Cuenta regresiva de escudo (8s) ----
	for i in range(8, -1, -1):
		actualizar_label_shield("SHIELD ACTIVATED – " + str(i))
		shield_label.position = Vector2( 2150, 70)
		await get_tree().create_timer(1.0).timeout

	shield_active = false

	# ---- RECHARGE 20 seconds ----
	for i in range(20, -1, -1):
		actualizar_label_shield("SHIELD RECHARGING – " + str(i))
		shield_label.position = Vector2( 2150, 70)
		await get_tree().create_timer(1.0).timeout

	shield_recharging = false

	actualizar_label_shield("SHIELD READY TO USE!")
	shield_label.position = Vector2( 2150, 70)
	await get_tree().create_timer(2.0).timeout

	if shield_label:
		shield_label.queue_free()
		shield_label = null

func _conectar_computadores():
	var computers = {
		computer: "res://hard_1.tscn",
		computer2: "res://hard_2.tscn",
		computer3: "res://hard_3.tscn",
		computer4: "res://hard_4.tscn",
		computer5: "res://hard_5.tscn"
	}

	print("\n🔌 Conectando minijuegos:")
	for comp in computers.keys():
		if comp:
			var path = computers[comp]
			
			# Verificar que el archivo existe
			if not ResourceLoader.exists(path):
				print("  ❌ ERROR: No existe el archivo:", path)
				continue
			
			# Desconectar primero si ya existe una conexión
			if comp.is_connected("interactuar", _on_computer_interactuar):
				comp.disconnect("interactuar", _on_computer_interactuar)
			
			# Conectar con la sintaxis correcta de Godot 4
			comp.connect("interactuar", _on_computer_interactuar.bind(path, comp))
			print("  ✓ Conectado:", comp.name, "→", path)


func buscar_todos_los_robbers():
	print("\n Buscando robbers manualmente y asignando correctamente...")

	robbers = [
		$robber,
		$robber2,
		$robber3,
		$robber4,
		$robber5
	]

	robber_to_computer = {
		$robber: computer,
		$robber2: computer4,
		$robber3: computer2,
		$robber4: computer3,
		$robber5: computer5
	}

	for rb in robbers:
		print("  ✓", rb.name, "→", robber_to_computer[rb].name)



func configurar_jugador():
	# Ocultar sprites y colisiones del jugador
	for name in ["agentep", "agentex", "agentez"]:
		var sprite = player.get_node_or_null(name)
		if sprite:
			sprite.visible = false
	
	for col_name in ["ap", "ax", "az"]:
		var col = player.get_node_or_null(col_name)
		if col:
			col.disabled = true
	
	# Obtener personaje seleccionado
	var game_manager = get_node("/root/GameManager")
	if game_manager and game_manager.has_method("get"):
		var selected = game_manager.get("selected_character")
		if selected:
			print(" Personaje seleccionado:", selected)
			
			var selected_sprite: AnimatedSprite2D = null
			var selected_collision: CollisionShape2D = null
			
			match selected:
				"agentep":
					selected_sprite = player.get_node_or_null("agentep")
					selected_collision = player.get_node_or_null("ap")
				"agentex":
					selected_sprite = player.get_node_or_null("agentex")
					selected_collision = player.get_node_or_null("ax")
				"agentez":
					selected_sprite = player.get_node_or_null("agentez")
					selected_collision = player.get_node_or_null("az")
			
			if selected_sprite and selected_collision:
				selected_sprite.visible = true
				selected_collision.disabled = false
				player.set("animated_sprite", selected_sprite)
				if selected_sprite.has_method("play"):
					selected_sprite.play("idle")
	else:
		print(" GameManager no encontrado, usando personaje por defecto")
		# Activar el primer personaje disponible como fallback
		var sprite = player.get_node_or_null("agentep")
		var collision = player.get_node_or_null("ap")
		if sprite and collision:
			sprite.visible = true
			collision.disabled = false
			player.set("animated_sprite", sprite)
			if sprite.has_method("play"):
				sprite.play("idle")


func _process(delta):
	if minijuego_en_progreso or game_over_mostrado or tiempo_extra_activo:
		return
	
	next_spawn -= delta
	
	if next_spawn <= 0:
		mostrar_robber_aleatorio()
		next_spawn = spawn_interval

func mostrar_robber_aleatorio():
	if robbers.size() == 0:
		print(" No hay robbers en la escena")
		return
	
	print("\n Buscando robber para aparecer...")
	
	var robbers_disponibles = []
	for rb in robbers:
		if not is_instance_valid(rb):
			continue
		
		var comp = robber_to_computer.get(rb)
		
		# Disponible si NO está completado Y NO ha aparecido antes
		if comp and not minijuegos_completados[comp] and not robbers_aparecidos[comp]:
			robbers_disponibles.append(rb)
			print("  Disponible:", rb.name)

	if robbers_disponibles.size() == 0:
		print("   No quedan robbers pendientes")
		verificar_fin_juego()
		return

	# Elegir prisionero aleatorio
	var rb = robbers_disponibles[randi() % robbers_disponibles.size()]
	var comp = robber_to_computer[rb]

	print("   Aparece:", rb.name, "→ Desbloquea:", comp.name)

	# Hacer visible el robber
	rb.visible = true

	# Animación y dirección aleatoria
	var sprite = rb.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("idle")

		# Dirección aleatoria: TRUE = izquierda, FALSE = derecha
		var mirar_izquierda = bool(randi() % 2)
		sprite.flip_h = mirar_izquierda

	# Marcar que ya apareció
	robbers_aparecidos[comp] = true
	
	var icon = comp.get_node_or_null("icon_alerta")
	if icon:
		icon.visible = true
		print("   Icono activado en:", comp.name)

	# DESBLOQUEAR la computadora
	if not minijuegos_completados[comp]:
		comp.is_blocked = false
		print("   DESBLOQUEADA:", comp.name, "- Ahora puedes presionar E para jugar")
	
	# Programar desaparición
	
	# Verificar estado del juego
	verificar_fin_juego()



func _on_computer_interactuar(minijuego_path: String, comp):
	print("\n🎮 Señal 'interactuar' recibida!")
	print("  Computadora:", comp.name)
	print("  Path:", minijuego_path)
	print("  Bloqueada:", comp.is_blocked)
	print("  Completada:", minijuegos_completados.get(comp, false))
	
	# 1. Si ya está COMPLETADO → no se puede abrir
	if minijuegos_completados.get(comp, false) == true:
		print("   Este minijuego ya fue completado y está bloqueado permanentemente")
		return

	# 2. Si está bloqueado porque no ha aparecido su robber
	if comp.is_blocked:
		print("   Aún no puedes jugar: espera a que aparezca el Robber")
		return

	print("   Abriendo minijuego...")
	minijuego_en_progreso = true
	abrir_minijuego(minijuego_path, comp)


func abrir_minijuego(path, comp):
	if minijuego_actual != null:
		print("   Ya hay un minijuego abierto")
		return
	
	# Pausar el jugador
	if player:
		player.set_process(false)
		player.set_physics_process(false)
	
	# Cargar el minijuego
	var scene = load(path)
	if scene == null:
		print("   ERROR: No se pudo cargar la escena:", path)
		print("  Verifica que el archivo existe en esa ruta")
		finalizar_cierre()
		return
	
	minijuego_actual = scene.instantiate()
	minijuego_actual.set_meta("computer", comp)
	
	# Verificar que UILayer existe
	var ui_layer = get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(minijuego_actual)
	else:
		print("  ⚠️ UILayer no encontrado, agregando minijuego directamente")
		add_child(minijuego_actual)
	
	# Conectar señales
	if minijuego_actual.has_signal("puzzle_completed"):
		minijuego_actual.connect("puzzle_completed", _cerrar_minijuego_exitoso)
		print("  ✓ Señal 'puzzle_completed' conectada")
	else:
		print("  ⚠️ El minijuego no tiene señal 'puzzle_completed'")
	
	if minijuego_actual.has_signal("puzzle_failed"):
		minijuego_actual.connect("puzzle_failed", _cerrar_minijuego_fallido)
		print("  ✓ Señal 'puzzle_failed' conectada")
	else:
		print("  ⚠️ El minijuego no tiene señal 'puzzle_failed'")
	
	print("   Minijuego cargado correctamente")
func _cerrar_minijuego_exitoso():
	print("\n Minijuego completado exitosamente!")

	if minijuego_actual and minijuego_actual.has_meta("computer"):
		var comp = minijuego_actual.get_meta("computer")
		
		# MARCAR COMO COMPLETADO Y BLOQUEAR PERMANENTEMENTE
		minijuegos_completados[comp] = true
		comp.is_blocked = true
		print("   Minijuego bloqueado permanentemente:", comp.name)
		
		# Ocultar robber si está visible
		for rb in robber_to_computer.keys():
			if robber_to_computer[rb] == comp and rb.visible:
				rb.visible = false
				print("   Ocultando robber:", rb.name)
		
		# Mostrar progreso
		var completados = minijuegos_completados.values().count(true)
		var aparecidos = robbers_aparecidos.values().count(true)
		var icon = comp.get_node_or_null("icon_alerta")
		if icon:
			icon.visible = false
			print("Icono apagado en:", comp.name)
		print("\n PROGRESO:")
		print("  Completados:", completados, "/", total_minijuegos)
		print("  Aparecidos:", aparecidos, "/", total_minijuegos)

	finalizar_cierre()
	 
	var completados = minijuegos_completados.values().count(true)
	
	if completados == total_minijuegos:
		# Ganaste, sin importar si estás o no en tiempo extra
		print(" ¡Todos los minijuegos completados!")
		mostrar_ventana_victoria()
	elif not tiempo_extra_activo:
		# Aún no estamos en tiempo extra: aquí sí usamos la lógica normal
		verificar_fin_juego()
	else:
		# Estamos en tiempo extra y todavía faltan minijuegos:
		# NO hacemos nada; el timer de 15 s decidirá luego en verificar_tiempo_extra()
		print(" Minijuego completado durante tiempo extra, pero aún faltan otros. Sigue jugando...")



func _cerrar_minijuego_fallido():
	print("\n Minijuego cerrado/fallido")
	print("   Puedes volver a intentarlo")
	
	finalizar_cierre()
	
	# Si estamos en tiempo extra y fallas, game over
	if tiempo_extra_activo:
		print("   Fallaste durante el tiempo extra - GAME OVER")
		mostrar_ventana_game_over()


func finalizar_cierre():
	if minijuego_actual:
		minijuego_actual.queue_free()
		minijuego_actual = null
	
	# Reactivar el jugador
	if player:
		player.set_process(true)
		player.set_physics_process(true)
	
	minijuego_en_progreso = false
	next_spawn = spawn_interval


func verificar_fin_juego():
	if game_over_mostrado or tiempo_extra_activo:
		return
	
	var completados = minijuegos_completados.values().count(true)
	var aparecidos = robbers_aparecidos.values().count(true)

	# Victoria
	if completados == total_minijuegos:
		print("\n VICTORIA! Todos los minijuegos completados!")
		mostrar_ventana_victoria()
		return

	# Activar tiempo extra si todos aparecieron pero no todos completados
	if aparecidos == total_minijuegos and completados < total_minijuegos:
		print("Todos los robbers han aparecido!")
		print(" You have 15 extra seconds to finish the remaining minigames – hurry up!")
		activar_tiempo_extra()


func activar_tiempo_extra():
	if tiempo_extra_activo:
		return
	
	tiempo_extra_activo = true
	
	print("EXTRA TIME ACTIVATED – 30 SECONDS!")
	mostrar_mensaje_tiempo_extra()
	
	# Timer de 10 segundos
	await get_tree().create_timer(30.0).timeout
	verificar_tiempo_extra()


func verificar_tiempo_extra():
	if game_over_mostrado:
		return
	
	var completados = minijuegos_completados.values().count(true)
	
	if completados == total_minijuegos:
		print(" Lo lograste en el último momento!")
		mostrar_ventana_victoria()
	else:
		print(" Se acabó el tiempo - GAME OVER")
		mostrar_ventana_game_over()


func mostrar_mensaje_tiempo_extra():
	var warning_label = Label.new()
	warning_label.text = "EXTRA TIME: 30 SECONDS!"
	warning_label.add_theme_font_size_override("font_size", 48)
	warning_label.add_theme_color_override("font_color", Color(0, 1.0, 1.0))
	warning_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	warning_label.add_theme_constant_override("shadow_offset_x", 3)
	warning_label.add_theme_constant_override("shadow_offset_y", 3)
	
	var viewport_size = get_viewport().size
	warning_label.position = Vector2(viewport_size.x / 2 - 290, 100)
	
	var ui_layer = get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(warning_label)
	else:
		add_child(warning_label)
	
	# Contador visual
	var countdown_label = Label.new()
	countdown_label.add_theme_font_size_override("font_size", 64)
	countdown_label.add_theme_color_override("font_color", Color(0, 1.0, 1.0))
	countdown_label.position = Vector2(viewport_size.x / 2 - 30, 180)
	
	if ui_layer:
		ui_layer.add_child(countdown_label)
	else:
		add_child(countdown_label)
	
	# Animación de cuenta regresiva
	for i in range(30, 0, -1):
		if game_over_mostrado or not tiempo_extra_activo:
			break
		countdown_label.text = str(i)
		
		var tween = create_tween()
		tween.tween_property(countdown_label, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.2)
		
		await get_tree().create_timer(1.0).timeout
	
	# Limpiar labels
	if is_instance_valid(warning_label):
		warning_label.queue_free()
	if is_instance_valid(countdown_label):
		countdown_label.queue_free()


func mostrar_ventana_game_over():
	if game_over_mostrado:
		return
	
	game_over_mostrado = true
	tiempo_extra_activo = false
	
	if player:
		player.set_process(false)
		player.set_physics_process(false)
	
	var game_over_scene = load("res://game_over_window_3.tscn")
	if game_over_scene == null:
		var game_over_window = create_game_over_window()
		var ui_layer = get_node_or_null("UILayer")
		if ui_layer:
			ui_layer.add_child(game_over_window)
		else:
			add_child(game_over_window)
	else:
		var game_over_window = game_over_scene.instantiate()
		var ui_layer = get_node_or_null("UILayer")
		if ui_layer:
			ui_layer.add_child(game_over_window)
		else:
			add_child(game_over_window)


func mostrar_ventana_victoria():
	if game_over_mostrado:
		return
	
	game_over_mostrado = true
	tiempo_extra_activo = false
	
	if player:
		player.set_process(false)
		player.set_physics_process(false)
	
	var win_scene = load("res://you_win_window_3.tscn")
	if win_scene == null:
		var win_window = create_win_window()
		var ui_layer = get_node_or_null("UILayer")
		if ui_layer:
			ui_layer.add_child(win_window)
		else:
			add_child(win_window)
	else:
		var win_window = win_scene.instantiate()
		var ui_layer = get_node_or_null("UILayer")
		if ui_layer:
			ui_layer.add_child(win_window)
		else:
			add_child(win_window)


func create_game_over_window() -> Control:
	var window = Control.new()
	var script = load("res://game_over_window_3.gd")
	if script:
		window.set_script(script)
	return window


func create_win_window() -> Control:
	var window = Control.new()
	var script = load("res://you_win_window_3.gd")
	if script:
		window.set_script(script)
	return window
	
func crear_label_shield():
	if shield_label:
		shield_label.queue_free()

	shield_label = Label.new()
	shield_label.add_theme_font_size_override("font_size", 48)
	shield_label.add_theme_color_override("font_color", Color.CYAN)
	shield_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	shield_label.add_theme_constant_override("shadow_offset_x", 3)
	shield_label.add_theme_constant_override("shadow_offset_y", 3)

	var viewport_size = get_viewport().size
	shield_label.position = Vector2(viewport_size.x / 2 - 260, 40)

	var ui_layer = get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(shield_label)
	else:
		add_child(shield_label)


func actualizar_label_shield(texto: String):
	if shield_label:
		shield_label.text = texto
