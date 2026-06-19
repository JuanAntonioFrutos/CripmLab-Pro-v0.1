extends Node

# Datos del usuario activo
var usuario_actual: String = ""
var peso_actual: float = 70.0
var edad_actual: int = 25
var altura_actual: int = 175

const PATH_PERFILES = "user://perfiles_usuarios.json"

func _ready():
	_cargar_ultimo_usuario()

# Ampliamos la función para que no borre los tests/historial si el usuario ya existía
func guardar_perfil(nombre, peso, edad, altura):
	usuario_actual = nombre
	peso_actual = peso
	edad_actual = edad
	altura_actual = altura
	
	var perfiles = _leer_todos_los_perfiles()
	
	# Si el usuario ya existía, recuperamos sus datos antiguos para no perderlos
	var test_max_antiguo = 0.0
	var test_resis_antiguo = 0.0
	var historial_antiguo = []
	
	if perfiles.has(nombre):
		test_max_antiguo = perfiles[nombre].get("mejor_test_max", 0.0)
		test_resis_antiguo = perfiles[nombre].get("mejor_test_resis", 0.0)
		historial_antiguo = perfiles[nombre].get("historial", [])
	
	# Guardamos la ficha completa guardando los datos físicos y deportivos
	perfiles[nombre] = {
		"peso": peso,
		"edad": edad,
		"altura": altura,
		"mejor_test_max": test_max_antiguo,
		"mejor_test_resis": test_resis_antiguo,
		"historial": historial_antiguo
	}
	
	var archivo = FileAccess.open(PATH_PERFILES, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(perfiles, "\t"))
	archivo.close()

# NUEVA FUNCIÓN: Guarda los resultados desde test_max, test_resis, entreno, etc.
func guardar_datos_de_test(tipo_test: String, valor_obtenido: float) -> void:
	if usuario_actual == "":
		print("UsuarioManager -> ERROR: No hay ningún usuario activo seleccionado.")
		return
		
	var perfiles = _leer_todos_los_perfiles()
	
	# Si por un casual el usuario activo no está en el JSON, aseguramos su estructura
	if not perfiles.has(usuario_actual):
		perfiles[usuario_actual] = {
			"peso": peso_actual, "edad": edad_actual, "altura": altura_actual,
			"mejor_test_max": 0.0, "mejor_test_resis": 0.0, "historial": []
		}
		
	# 1. Actualizamos récords históricos según el test
	if tipo_test == "test_max" and valor_obtenido > perfiles[usuario_actual].get("mejor_test_max", 0.0):
		perfiles[usuario_actual]["mejor_test_max"] = valor_obtenido
	elif tipo_test == "test_resis" and valor_obtenido > perfiles[usuario_actual].get("mejor_test_resis", 0.0):
		perfiles[usuario_actual]["mejor_test_resis"] = valor_obtenido

	# 2. Creamos una entrada cronológica para el Historial
	var nuevo_registro = {
		"tipo": tipo_test,
		"valor": valor_obtenido,
		"fecha": Time.get_date_string_from_system(),
		"hora": Time.get_time_string_from_system()
	}
	
	# Aseguramos que la lista exista y añadimos el registro
	if not perfiles[usuario_actual].has("historial"):
		perfiles[usuario_actual]["historial"] = []
	perfiles[usuario_actual]["historial"].append(nuevo_registro)
	
	# 3. Guardamos inmediatamente en el almacenamiento local físico del teléfono (.json)
	var archivo = FileAccess.open(PATH_PERFILES, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(perfiles, "\t"))
	archivo.close()
	
	print("UsuarioManager -> Test guardado con éxito en JSON para: ", usuario_actual)

func _leer_todos_los_perfiles() -> Dictionary:
	if not FileAccess.file_exists(PATH_PERFILES): return {}
	var archivo = FileAccess.open(PATH_PERFILES, FileAccess.READ)
	var datos = JSON.parse_string(archivo.get_as_text())
	archivo.close() # Buena práctica cerrarlo tras leer
	return datos if datos is Dictionary else {}

func _cargar_ultimo_usuario():
	var perfiles = _leer_todos_los_perfiles()
	if not perfiles.is_empty():
		var primer_nombre = perfiles.keys()[0]
		usuario_actual = primer_nombre
		peso_actual = perfiles[primer_nombre]["peso"]
		# Añadimos la carga del resto de datos físicos para mantener consistencia
		edad_actual = perfiles[primer_nombre].get("edad", 25)
		altura_actual = perfiles[primer_nombre].get("altura", 175)
