extends Node

# Datos del usuario activo
var usuario_actual: String = ""
var peso_actual: float = 70.0
var edad_actual: int = 25
var altura_actual: int = 175

const PATH_PERFILES = "user://perfiles_usuarios.json"

func _ready():
	_cargar_ultimo_usuario()

func guardar_perfil(nombre, peso, edad, altura):
	usuario_actual = nombre
	peso_actual = peso
	edad_actual = edad
	altura_actual = altura
	
	var perfiles = _leer_todos_los_perfiles()
	perfiles[nombre] = {
		"peso": peso,
		"edad": edad,
		"altura": altura
	}
	
	var archivo = FileAccess.open(PATH_PERFILES, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(perfiles, "\t"))
	archivo.close()

func _leer_todos_los_perfiles() -> Dictionary:
	if not FileAccess.file_exists(PATH_PERFILES): return {}
	var archivo = FileAccess.open(PATH_PERFILES, FileAccess.READ)
	var datos = JSON.parse_string(archivo.get_as_text())
	return datos if datos is Dictionary else {}

func _cargar_ultimo_usuario():
	# Por defecto, si no hay usuarios, se queda vacío
	var perfiles = _leer_todos_los_perfiles()
	if not perfiles.is_empty():
		var primer_nombre = perfiles.keys()[0]
		usuario_actual = primer_nombre
		peso_actual = perfiles[primer_nombre]["peso"]
