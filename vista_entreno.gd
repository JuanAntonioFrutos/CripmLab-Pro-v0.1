extends VBoxContainer

var main_referencia: Node = null

# --- Lógica de Entrenamiento ---
var test_activo: bool = false
var estado: String = "IDLE" # IDLE, PREPARA, TRACCION, DESCANSO
var tiempo_restante: float = 0.0
var repeticion_actual: int = 1
var total_repeticiones: int = 6

var fuerza_objetivo_kg: float = 0.0
var peso_recibido: float = 0.0
var segundo_actual_int: int = -1

# --- Configuración de Gráfica ---
var datos_grafica: Array = []
var max_puntos_grafica: int = 120
var ancho_panel_grafica: float = 340.0
var alto_panel_grafica: float = 160.0

# --- Ruta del archivo local para guardar entrenamientos ---
const RUTA_RUTINAS_FILE = "user://rutinas_entrenamiento_local.cfg"
var diccionario_rutinas_local: Dictionary = {}

# --- Botón de eliminar generado por código ---
var btn_eliminar_rutina: Button = null

# --- Referencias Nodos UI ---
@onready var selector_rutinas = %SelectorRutinas
@onready var label_estado = %LabelEstado
@onready var contenedor_estado = %ContenedorEstado
@onready var display_kilos = %DisplayKilos
@onready var grafica = %GraficaLineal
@onready var banda_objetivo = %BandaObjetivo

@onready var input_hang = %InputHang
@onready var input_rest = %InputRest
@onready var input_reps = %InputReps
@onready var input_porcentaje = %InputPorc
@onready var input_mano = %InputMano
@onready var label_target_info = %LabelTargetInfo

# 🌟 CORRECCIÓN DE NOMBRES EXACTOS (Según tu archivo .tscn)
@onready var input_nombre_rutina = %InputNombreConfig if has_node("%InputNombreConfig") else get_node_or_null("HBoxGuardado/InputNombreConfig")
@onready var btn_guardar_rutina = %BtnGuardarConfig if has_node("%BtnGuardarConfig") else get_node_or_null("HBoxGuardado/BtnGuardarConfig")

@onready var btn_iniciar = %BtnIniciar if has_node("%BtnIniciar") else get_node_or_null("HBoxBotones/BtnIniciar")
@onready var btn_parar = %BtnParar if has_node("%BtnParar") else get_node_or_null("HBoxBotones/BtnParar")

func _ready():
	if UsuarioManager.usuario_actual != "":
		$TuLabelUsuario.text = "Atleta: " + UsuarioManager.usuario_actual
	else:
		$TuLabelUsuario.text = "Sin atleta seleccionado"
	
	
	
	add_to_group("interfaz_rediseñable")
	_on_estilos_actualizados()
	
	# 🌟 CREACIÓN DEL BOTÓN ELIMINAR (Se inyecta al lado de "Cargar Entrenamiento")
	var hbox_selector = get_node_or_null("HBoxSelectorRutinas")
	if is_instance_valid(hbox_selector):
		btn_eliminar_rutina = Button.new()
		btn_eliminar_rutina.text = " Eliminar "
		btn_eliminar_rutina.custom_minimum_size = Vector2(0, 35)
		# Le damos un toque rojo discreto para indicar peligro/borrado
		btn_eliminar_rutina.add_theme_color_override("font_color", Color("#ff5555"))
		hbox_selector.add_child(btn_eliminar_rutina)
		btn_eliminar_rutina.pressed.connect(_on_eliminar_rutina_clicked)

	# Rellenar Opciones del selector de Mano
	if is_instance_valid(input_mano):
		input_mano.clear()
		input_mano.add_item("Mano Izquierda")
		input_mano.add_item("Mano Derecha")
		input_mano.add_item("Ambas (Alternando)")
		input_mano.selected = 0
	
	# Conexiones de botones principales seguras
	if is_instance_valid(btn_iniciar):
		if btn_iniciar.pressed.is_connected(_on_iniciar_entreno):
			btn_iniciar.pressed.disconnect(_on_iniciar_entreno)
		btn_iniciar.pressed.connect(_on_iniciar_entreno)
		
	if is_instance_valid(btn_parar):
		if btn_parar.pressed.is_connected(_on_parar_entreno):
			btn_parar.pressed.disconnect(_on_parar_entreno)
		btn_parar.pressed.connect(_on_parar_entreno)
	
	# Conexión del botón de Guardar corregida
	if is_instance_valid(btn_guardar_rutina): 
		if btn_guardar_rutina.pressed.is_connected(_on_guardar_rutina_clicked): 
			btn_guardar_rutina.pressed.disconnect(_on_guardar_rutina_clicked)
		btn_guardar_rutina.pressed.connect(_on_guardar_rutina_clicked)
		
	if is_instance_valid(selector_rutinas): 
		if selector_rutinas.item_selected.is_connected(_on_rutina_seleccionada): 
			selector_rutinas.item_selected.disconnect(_on_rutina_seleccionada)
		selector_rutinas.item_selected.connect(_on_rutina_seleccionada)
	
	if is_instance_valid(input_porcentaje):
		input_porcentaje.value_changed.connect(func(_v): _recalcular_fuerza_objetivo())
	if is_instance_valid(input_mano):
		input_mano.item_selected.connect(func(_i): _recalcular_fuerza_objetivo())
	
	# Cargar datos desde el almacenamiento físico local de la app
	_cargar_rutinas_desde_disco()
	_cargar_lista_rutinas_en_ui()
	_recalcular_fuerza_objetivo()
	_cambiar_estado_sistema("IDLE")

func inicializar(main_node):
	main_referencia = main_node
	_recalcular_fuerza_objetivo()
	_cambiar_estado_sistema("IDLE")

func _on_estilos_actualizados():
	pass

func _cambiar_estado_sistema(nuevo_estado: String):
	estado = nuevo_estado
	if not main_referencia or not main_referencia.has_method("cambiar_color_fondo_sistema"):
		return

	var estilo_caja = StyleBoxFlat.new()
	estilo_caja.corner_radius_top_left = 10
	estilo_caja.corner_radius_top_right = 10
	estilo_caja.corner_radius_bottom_right = 10
	estilo_caja.corner_radius_bottom_left = 10
	estilo_caja.content_margin_top = 8
	estilo_caja.content_margin_bottom = 8

	match nuevo_estado:
		"IDLE":
			label_estado.text = "LISTO"
			estilo_caja.bg_color = Color("#232329")
			main_referencia.cambiar_color_fondo_sistema("NORMAL")
		"PREPARA":
			label_estado.text = "¡PREPARA! %d" % ceili(tiempo_restante)
			estilo_caja.bg_color = Color("#d35400")
			main_referencia.cambiar_color_fondo_sistema("PREPARACION")
		"TRACCION":
			label_estado.text = "¡TIRA! (Rep %d/%d) - %ds" % [repeticion_actual, total_repeticiones, ceili(tiempo_restante)]
			estilo_caja.bg_color = Color("#c0392b")
			main_referencia.cambiar_color_fondo_sistema("TRACCION")
		"DESCANSO":
			label_estado.text = "DESCANSO - %ds" % ceili(tiempo_restante)
			estilo_caja.bg_color = Color("#27ae60")
			main_referencia.cambiar_color_fondo_sistema("DESCANSO")

	if is_instance_valid(contenedor_estado):
		contenedor_estado.add_theme_stylebox_override("panel", estilo_caja)

func _process(delta):
	if not test_activo: return
	tiempo_restante -= delta
	if tiempo_restante < 0: tiempo_restante = 0
	_actualizar_ui_cronometro()
	if tiempo_restante <= 0:
		_avanzar_maquina_estados()

func _actualizar_ui_cronometro():
	var seg_actual = ceili(tiempo_restante)
	if seg_actual != segundo_actual_int:
		segundo_actual_int = seg_actual
		_cambiar_estado_sistema(estado)
		if (estado == "PREPARA" or estado == "TRACCION") and seg_actual <= 3 and seg_actual > 0:
			_decir_voz(str(seg_actual))
	if estado == "TRACCION":
		_dibujar_grafica()

func _avanzar_maquina_estados():
	match estado:
		"PREPARA":
			tiempo_restante = input_hang.value
			_cambiar_estado_sistema("TRACCION")
			_decir_voz("Tira")
		"TRACCION":
			if repeticion_actual < total_repeticiones:
				tiempo_restante = input_rest.value
				_cambiar_estado_sistema("DESCANSO")
				_decir_voz("Descansa")
			else:
				_finalizar_entreno_exito()
		"DESCANSO":
			repeticion_actual += 1
			tiempo_restante = 4.0
			_cambiar_estado_sistema("PREPARA")
			_decir_voz("Siguiente")

func _on_iniciar_entreno():
	if test_activo: return
	repeticion_actual = 1
	total_repeticiones = int(input_reps.value)
	_recalcular_fuerza_objetivo()
	test_activo = true
	estado = "PREPARA"
	tiempo_restante = 4.0
	datos_grafica.clear()
	_desactivar_ui(true)
	_cambiar_estado_sistema("PREPARA")
	_decir_voz("Iniciando serie de entrenamiento")

func _on_parar_entreno():
	if not test_activo: return
	test_activo = false
	_desactivar_ui(false)
	_cambiar_estado_sistema("IDLE")
	_decir_voz("Entrenamiento cancelado")

func _finalizar_entreno_exito():
	test_activo = false
	_desactivar_ui(false)
	_cambiar_estado_sistema("IDLE")
	label_estado.text = "¡SERIE COMPLETADA!"
	_decir_voz("Entrenamiento completado de forma excelente")

func _recalcular_fuerza_objetivo():
	if not is_instance_valid(input_mano) or not is_instance_valid(input_porcentaje): return
	var es_izq = input_mano.selected == 0
	var max_record = RegletasManager.record_max_izq if es_izq else RegletasManager.record_max_der
	var pct = input_porcentaje.value
	fuerza_objetivo_kg = (max_record * pct) / 100.0
	if is_instance_valid(label_target_info):
		label_target_info.text = "Target: %.1f Kg (Basado en Max: %.1f Kg)" % [fuerza_objetivo_kg, max_record]

func _desactivar_ui(bloquear: bool):
	if is_instance_valid(btn_iniciar): btn_iniciar.disabled = bloquear
	if is_instance_valid(input_hang): input_hang.editable = not bloquear
	if is_instance_valid(input_rest): input_rest.editable = not bloquear
	if is_instance_valid(input_reps): input_reps.editable = not bloquear
	if is_instance_valid(input_porcentaje): input_porcentaje.editable = not bloquear
	if is_instance_valid(input_mano): input_mano.disabled = bloquear
	if is_instance_valid(selector_rutinas): selector_rutinas.disabled = bloquear
	if is_instance_valid(btn_eliminar_rutina): btn_eliminar_rutina.disabled = bloquear

func actualizar_peso(kilos: float):
	peso_recibido = kilos
	if is_instance_valid(display_kilos):
		display_kilos.text = "%.1f Kg" % kilos

func _dibujar_grafica():
	if not is_instance_valid(grafica): return
	datos_grafica.append(peso_recibido)
	if datos_grafica.size() > max_puntos_grafica:
		datos_grafica.remove_at(0)
	grafica.clear_points()
	for i in range(datos_grafica.size()):
		var x = (float(i) / max_puntos_grafica) * ancho_panel_grafica
		var y = alto_panel_grafica - (datos_grafica[i] * 2.0)
		grafica.add_point(Vector2(x, y))

func _decir_voz(texto: String):
	if not ConfigManager.voz_activa: return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH): return
	var vol_android: int = clampi(int(ConfigManager.volumen_voz * 100.0), 0, 100)
	DisplayServer.tts_speak(texto, "", vol_android)

# --- GESTIÓN DE PERSISTENCIA LOCAL DE ENTRENAMIENTOS ---

func _cargar_rutinas_desde_disco():
	var config = ConfigFile.new()
	var error = config.load(RUTA_RUTINAS_FILE)
	if error == OK:
		diccionario_rutinas_local = config.get_value("Perfiles", "lista", {})
	
	# Mantener los dos perfiles fijos por defecto
	if not diccionario_rutinas_local.has("Fuerza Resistencia 80%"):
		diccionario_rutinas_local["Fuerza Resistencia 80%"] = {"hang": 7, "rest": 3, "reps": 6, "porcentaje": 80, "mano_idx": 2}
	if not diccionario_rutinas_local.has("Resistencia Activa 60%"):
		diccionario_rutinas_local["Resistencia Activa 60%"] = {"hang": 10, "rest": 5, "reps": 4, "porcentaje": 60, "mano_idx": 0}
	_guardar_rutinas_a_disco()

func _guardar_rutinas_a_disco():
	var config = ConfigFile.new()
	config.set_value("Perfiles", "lista", diccionario_rutinas_local)
	config.save(RUTA_RUTINAS_FILE)

func _cargar_lista_rutinas_en_ui():
	if not is_instance_valid(selector_rutinas): return
	selector_rutinas.clear()
	selector_rutinas.add_item("-- Selecciona Rutina --")
	for nombre in diccionario_rutinas_local.keys():
		selector_rutinas.add_item(nombre)

func _on_rutina_seleccionada(index: int):
	if index <= 0 or not is_instance_valid(selector_rutinas): return
	var nombre_r = selector_rutinas.get_item_text(index)
	if diccionario_rutinas_local.has(nombre_r):
		var r = diccionario_rutinas_local[nombre_r]
		if is_instance_valid(input_hang): input_hang.value = r.get("hang", 7)
		if is_instance_valid(input_rest): input_rest.value = r.get("rest", 3)
		if is_instance_valid(input_reps): input_reps.value = r.get("reps", 6)
		if is_instance_valid(input_porcentaje): input_porcentaje.value = r.get("porcentaje", 80)
		if is_instance_valid(input_mano): input_mano.selected = r.get("mano_idx", 0)
		_recalcular_fuerza_objetivo()

func _on_guardar_rutina_clicked():
	if not is_instance_valid(input_nombre_rutina): return
	var nombre = input_nombre_rutina.text.strip_edges()
	if nombre == "": return

	var datos = {
		"hang": input_hang.value if is_instance_valid(input_hang) else 7,
		"rest": input_rest.value if is_instance_valid(input_rest) else 3,
		"reps": input_reps.value if is_instance_valid(input_reps) else 6,
		"porcentaje": input_porcentaje.value if is_instance_valid(input_porcentaje) else 80,
		"mano_idx": input_mano.selected if is_instance_valid(input_mano) else 0
	}
	
	diccionario_rutinas_local[nombre] = datos
	_guardar_rutinas_a_disco()
	
	if "rutinas_entreno" in RegletasManager:
		RegletasManager.rutinas_entreno = diccionario_rutinas_local
		
	_cargar_lista_rutinas_en_ui()
	input_nombre_rutina.text = ""
	
	# Autoseleccionar la nueva rutina guardada
	for i in range(selector_rutinas.item_count):
		if selector_rutinas.get_item_text(i) == nombre:
			selector_rutinas.selected = i
			break

func _on_eliminar_rutina_clicked():
	if not is_instance_valid(selector_rutinas) or selector_rutinas.selected <= 0: return
	var nombre = selector_rutinas.get_item_text(selector_rutinas.selected)
	
	# Protegemos las rutinas por defecto para que no se puedan borrar
	if nombre == "Fuerza Resistencia 80%" or nombre == "Resistencia Activa 60%":
		return
		
	if diccionario_rutinas_local.has(nombre):
		diccionario_rutinas_local.erase(nombre)
		_guardar_rutinas_a_disco()
		
		if "rutinas_entreno" in RegletasManager:
			RegletasManager.rutinas_entreno = diccionario_rutinas_local
			
		_cargar_lista_rutinas_en_ui()
		selector_rutinas.selected = 0
