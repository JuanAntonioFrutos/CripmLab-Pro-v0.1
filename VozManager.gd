extends Node

var tts_disponible: bool = false

func _ready():
	# Inicializamos el servidor de voz en el arranque global de la app
	var voces = DisplayServer.tts_get_voices_for_language("es")
	if voces.size() > 0:
		tts_disponible = true
		print("[VOZ] Servidor TTS activado en Español correctamente.")
	else:
		print("[VOZ] Advertencia: No se encontraron voces en español en el dispositivo.")

func decir(texto: String):
	if tts_disponible:
		# Detenemos cualquier frase que se esté diciendo para que no se pisen
		DisplayServer.tts_stop()
		# Cantamos la nueva instrucción
		DisplayServer.tts_speak(texto, "es")
	else:
		print("[VOZ SIMULADA]: ", texto)
