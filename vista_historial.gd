extends VBoxContainer

var main_referencia: Node = null

# Dimensiones internas del panel de la gráfica para el escalado matemático
var ancho_grafica: float = 340.0
var alto_grafica: float = 180.0
var max_escala_kilos: float = 100.0

# 🌟 REFERENCIAS MEDIANTE RUTA DIRECTA
@onready var selector_mano = $HBoxFiltro/SelectorMano
@onready var linea_fuerza = $PanelGrafica/LineaFuerza
@onready var linea_resistencia = $PanelGrafica/LineaResistencia
@onready var linea_entreno = $PanelGrafica/LineaEntreno
@onready var cuerpo_tabla = $ScrollTabla/ContenedorTabla/CuerpoTabla

# Estructuras de datos limpias por mano
var datos_izq: Array = []
var datos_der: Array = []

func inicializar(main_node):
	if UsuarioManager.usuario_actual != "":
		$TuLabelUsuario.text = "Atleta: " + UsuarioManager.usuario_actual
	else:
		$TuLabelUsuario.text = "Sin atleta seleccionado"
	
	main_referencia = main_node
	add_to_group("interfaz_rediseñable")
	
	# Configurar selector de mano
	selector_mano.clear()
	selector_mano.add_item("Mano Izquierda")
	selector_mano.add_item("Mano Derecha")
	
	if not selector_mano.item_selected.is_connected(_on_mano_cambiada):
		selector_mano.item_selected.connect(_on_mano_cambiada)
	
	# Cargar y procesar el histórico centralizado
	_cargar_datos_desde_disco()
	_actualizar_pantalla()
	
	if ConfigManager.has_method("aplicar_estilos_dinamicos"):
		ConfigManager.aplicar_estilos_dinamicos(self)

func _cargar_datos_desde_disco():
	datos_izq.clear()
	datos_der.clear()
	
	var usuario = UsuarioManager.usuario_actual
	if usuario == "": 
		print("No hay ningún usuario activo en UsuarioManager.")
		return
	
	# 1. Leemos el JSON maestro a través del método existente en tu UsuarioManager
	var perfiles = UsuarioManager._leer_todos_los_perfiles()
	
	# 2. Si el usuario tiene historial guardado en el sistema central, lo procesamos
	if perfiles.has(usuario) and perfiles[usuario].has("historial"):
		var lista_entrenos = perfiles[usuario]["historial"]
		print("Procesando historial desde el JSON central para: ", usuario)
		
		for registro in lista_entrenos:
			var fecha_completa = registro.get("fecha", "00/00")
			var tipo = registro.get("tipo", "")
			var valor = registro.get("valor", 0.0)
			
			# Formateamos la estructura para que tus Line2D y la tabla la entiendan de forma nativa
			# Nota: Si en el futuro guardas la mano ("izq" o "der") en el test, podrás filtrarlo aquí.
			# De momento, para asegurar la retrocompatibilidad, lo añadimos a ambas listas.
			var estructura_punto = {
				"fecha": fecha_completa.substr(0, 5), # Corta a "DD/MM" para la gráfica
				"fuerza": valor if tipo == "test_max" else 0.0,
				"resistencia": valor if tipo == "test_resis" else 0.0,
				"entreno": valor if tipo == "entreno" else 0.0
			}
			
			datos_izq.append(estructura_punto)
			datos_der.append(estructura_punto)
			
		print("Historial cargado con éxito para el usuario: ", usuario)
	else:
		# 💡 Si el archivo real no existe aún para este usuario, generamos
		# datos simulados temporales para que la gráfica no salga vacía mientras prueba
		print("No se encontró historial real en el mánager. Generando ejemplos para: ", usuario)
		var fechas = ["01/06", "02/06", "03/06", "04/06", "05/06"]
		
		for i in range(fechas.size()):
			datos_izq.append({
				"fecha": fechas[i],
				"fuerza": 32.0 + (i * 1.5),
				"resistencia": 35.0 + (i * 2.0),
				"entreno": 22.0 + (i * 1.2)
			})
			
			datos_der.append({
				"fecha": fechas[i],
				"fuerza": 36.0 + (i * 1.2),
				"resistencia": 40.0 + (i * 1.5),
				"entreno": 25.0 + (i * 1.0)
			})

func _on_mano_cambiada(_index: int):
	_actualizar_pantalla()

func _actualizar_pantalla():
	var datos_actuales = datos_izq if selector_mano.selected == 0 else datos_der
	_dibujar_lineas_grafica(datos_actuales)
	_llenar_tabla_datos(datos_actuales)

func _dibujar_lineas_grafica(datos: Array):
	linea_fuerza.clear_points()
	linea_resistencia.clear_points()
	linea_entreno.clear_points()
	
	if datos.is_empty(): return
	
	var total_puntos = datos.size()
	for i in range(total_puntos):
		var x = 0.0
		if total_puntos > 1:
			x = (float(i) / (total_puntos - 1)) * ancho_grafica
			
		var d = datos[i]
		var y_fuerza = alto_grafica - (d["fuerza"] / max_escala_kilos * alto_grafica)
		var y_resis = alto_grafica - (d["resistencia"] / max_escala_kilos * alto_grafica)
		var y_entreno = alto_grafica - (d["entreno"] / max_escala_kilos * alto_grafica)
		
		y_fuerza = clamp(y_fuerza, 0.0, alto_grafica)
		y_resis = clamp(y_resis, 0.0, alto_grafica)
		y_entreno = clamp(y_entreno, 0.0, alto_grafica)
		
		linea_fuerza.add_point(Vector2(x, y_fuerza))
		linea_resistencia.add_point(Vector2(x, y_resis))
		linea_entreno.add_point(Vector2(x, y_entreno))

func _llenar_tabla_datos(datos: Array):
	# 1. Limpiar filas previas de la tabla antes de reconstruir
	for child in cuerpo_tabla.get_children():
		child.queue_free()
		
	# 2. Recorrer a la inversa para mostrar las sesiones más recientes primero
	var datos_invertidos = datos.duplicate()
	datos_invertidos.reverse()
	
	for d in datos_invertidos:
		# Evitamos división por cero si el peso del usuario es 0 por algún error
		var peso_usuario = UsuarioManager.peso_actual if UsuarioManager.peso_actual > 0 else 70.0
		var porcentaje_fuerza = (d["fuerza"] / peso_usuario) * 100.0
		
		# --- Columna 1: Fecha ---
		var lbl_fecha = Label.new()
		lbl_fecha.text = str(d["fecha"])
		lbl_fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_fecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cuerpo_tabla.add_child(lbl_fecha)
		
		# --- Columna 2: Fuerza Max + % de su peso ---
		var lbl_fuerza = Label.new()
		lbl_fuerza.text = "%.1f Kg (%.1f%%)" % [d["fuerza"], porcentaje_fuerza]
		lbl_fuerza.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_fuerza.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cuerpo_tabla.add_child(lbl_fuerza)
		
		# --- Columna 3: Resistencia ---
		var lbl_resis = Label.new()
		lbl_resis.text = "%.1f s" % d["resistencia"]
		lbl_resis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_resis.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cuerpo_tabla.add_child(lbl_resis)
		
		# --- Columna 4: Media de Entreno ---
		var lbl_entreno = Label.new()
		lbl_entreno.text = "%.1f Kg" % d["entreno"]
		lbl_entreno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_entreno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cuerpo_tabla.add_child(lbl_entreno)

func _on_estilos_actualizados():
	queue_redraw()
