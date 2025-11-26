extends Node

# Guarda el personaje seleccionado globalmente
var selected_character: String = ""

# (Opcional) Si planeas usar escenas de personajes luego:
var character_scenes = {
	"agentep": "res://agentep.tscn",
	"agentex": "res://agentex.tscn",
	"agentez": "res://agentez.tscn"
}

func get_selected_character_scene():
	if selected_character in character_scenes:
		return character_scenes[selected_character]
	return null
