extends VBoxContainer

var main_referencia: Node = null

var test_activo: bool = false
var estado_test: String = "IDLE" # IDLE, PREPARA, ESPERANDO_GATILLO, TRACCION
var tiempo_transcurrido: float = 0.0
var tiempo_restante_prepara: float = 5.0

var peso_recibido: float = 0.0
var fuerza_objetivo_kg: float = 0.0
var segundo_actual_int: int = -1
var tiempo_bajo_objetivo: float = 0.0

var datos_grafica: Array = []
var max_puntos_grafica: int = 150 

@onready var label_estado = get_node_or_null("%LabelEstado")
@onready var contenedor_estado = get_node_or_null("%ContenedorEstado")
@onready var display_tiempo = get_node_or_null("%DisplayTiempo")
@onready var display_kilos = get_node_or_null("%DisplayKilos")
@onready var grafica = get_node_or_null("%GraficaLineal")
@onready var input_porcentaje = get_node_or_null("%InputPorcentaje")
@onready var input_mano = get_node_or_null("%InputMano")
@onready var label_info_objetivo = get_node_or_null("%LabelInfoObjetivo")
@onready var btn_comenzar = get_node_or_null("%BtnComenzarTest")
@onready var btn_parar = get_node_or_null("%BtnParaTest")

func _ready():
	if is_instance_valid(input_porcentaje):
		input_porcentaje.value = 80
		input_porcentaje.value_changed.connect(func(_v): _recalcular_fuerza_objetivo())
		
	if is_instance_valid(input_mano):
		input_mano.clear()
		input_mano.add_item("Mano Izquierda")
		input_mano.add_item("Mano Derecha")
		input_mano.selected = 0
		input_mano.item_selected.connect(func(_i): _recalcular_fuerza_objetivo())
		
	if is_instance_valid(btn_comenzar): btn_comenzar.pressed.connect(_on_comenzar)
	if is_instance_valid(btn_parar): btn_parar.pressed.connect(_on_parar)
	
	_recalcular_fuerza_objetivo()
	_cambiar_estado_sistema("IDLE")

func inicializar(main_node):
	main_referencia = main_node
	_recalcular_fuerza_objetivo()

# 🌟 NUEVA FUNCIÓN: Cambia el fondo del MainContainer según el estado actual en Resistencia
func _cambiar_estado_sistema(nuevo_estado: String):
	estado_test = nuevo_estado
	
	if not main_referencia or not main_referencia.has_method("cambiar_color_fondo_sistema"):
		return

	# Creamos el diseño de la tarjeta de estado
	var estilo_caja = StyleBoxFlat.new()
	estilo_caja.corner_radius_top_left = 10
	estilo_caja.corner_radius_top_right = 10
	estilo_caja.corner_radius_bottom_left = 10
	estilo_caja.corner_radius_bottom_right = 10
	estilo_caja.content_margin_top = 8
	estilo_caja.content_margin_bottom = 8

	match nuevo_estado:
		"IDLE":
			if is_instance_valid(label_estado): label_estado.text = "LISTO"
			estilo_caja.bg_color = Color("#232329") # Gris neutro
			main_referencia.cambiar_color_fondo_sistema("NORMAL")
		"PREPARA":
			if is_instance_valid(label_estado): 
				label_estado.text = "¡PREPARA! %d" % ceili(tiempo_restante_prepara)
			estilo_caja.bg_color = Color("#d35400") # 🟧 Fondo de tarjeta Naranja
			main_referencia.cambiar_color_fondo_sistema("PREPARACION")
		"ESPERANDO_GATILLO":
			if is_instance_valid(label_estado): 
				label_estado.text = "TIRA PARA EMPEZAR (Min: %.1f Kg)" % (fuerza_objetivo_kg * 0.8)
			estilo_caja.bg_color = Color("#f39c12") # Amarillo/Naranja intermedio en espera
			main_referencia.cambiar_color_fondo_sistema("PREPARACION")
		"TRACCION":
			if is_instance_valid(label_estado): label_estado.text = "¡MANTÉN LA TENSIÓN!"
			estilo_caja.bg_color = Color("#c0392b") # 🟥 Fondo de tarjeta Rojo
			main_referencia.cambiar_color_fondo_sistema("TRACCION")
		"FINALIZADO":
			if is_instance_valid(label_estado): label_estado.text = "TEST COMPLETADO"
			estilo_caja.bg_color = Color("#232329")
			main_referencia.cambiar_color_fondo_sistema("NORMAL")

	# Aplicamos el estilo al panel contenedor del texto
	if is_instance_valid(contenedor_estado):
		contenedor_estado.add_theme_stylebox_override("panel", estilo_caja)

func _recalcular_fuerza_objetivo():
	var es_izq = true
	if is_instance_valid(input_mano):
		es_izq = input_mano.selected == 0
		
	var max_record = RegletasManager.record_max_izq if es_izq else RegletasManager.record_max_der
	var pct = 80.0
	if is_instance_valid(input_porcentaje):
		pct = input_porcentaje.value
		
	fuerza_objetivo_kg = (max_record * pct) / 100.0
	if is_instance_valid(label_info_objetivo):
		label_info_objetivo.text = "Objetivo: %.1f Kg (Basado en Max: %.1f Kg)" % [fuerza_objetivo_kg, max_record]

func _process(delta):
	if not test_activo: return
	
	match estado_test:
		"PREPARA":
			tiempo_restante_prepara -= delta
			_cambiar_estado_sistema("PREPARA")
			
			var seg_int = ceili(tiempo_restante_prepara)
			if seg_int != segundo_actual_int:
				segundo_actual_int = seg_int
				if seg_int <= 3 and seg_int > 0: _decir_voz(str(seg_int))
				
			if tiempo_restante_prepara <= 0:
				tiempo_under_trigger_check = 0.0
				_cambiar_estado_sistema("ESPERANDO_GATILLO")
				_decir_voz("Tira")
				
		"ESPERANDO_GATILLO":
			if peso_received_frame >= (fuerza_objetivo_kg * 0.8):
				tiempo_under_trigger_check += delta
				if tiempo_under_trigger_check >= 0.3: 
					tiempo_transcurrido = 0.0
					tiempo_bajo_objetivo = 0.0
					datos_grafica.clear()
					_cambiar_estado_sistema("TRACCION")
					_decir_voz("Ya")
			else:
				tiempo_under_trigger_check = 0.0
				
		"TRACCION":
			tiempo_transcurrido += delta
			if is_instance_valid(display_tiempo):
				display_tiempo.text = "%.1f s" % tiempo_transcurrido
				
			if peso_received_frame < (fuerza_objetivo_kg * 0.5):
				tiempo_bajo_objetivo += delta
				if tiempo_bajo_objetivo >= 2.0:
					_finalizar_test_exito()
			else:
				tiempo_bajo_objetivo = 0.0
				
			_dibujar_grafica()

var peso_received_frame: float = 0.0
var tiempo_under_trigger_check: float = 0.0

func actualizar_peso(kilos: float):
	peso_received_frame = kilos
	if is_instance_valid(display_kilos):
		display_kilos.text = "%.1f Kg" % kilos

func _on_comenzar():
	if test_activo: return
	_recalcular_fuerza_objetivo()
	
	test_activo = true
	tiempo_restante_prepara = 5.0
	segundo_actual_int = -1
	_desactivar_controles(true)
	_cambiar_estado_sistema("PREPARA")
	_decir_voz("Prepararse")

func _on_parar():
	if not test_activo: return
	test_activo = false
	_desactivar_controles(false)
	_reset_ui_valores()
	_cambiar_estado_sistema("IDLE")
	_decir_voz("Test cancelado")

func _finalizar_test_exito():
	test_activo = false
	_desactivar_controles(false)
	_cambiar_estado_sistema("FINALIZADO")
	_decir_voz("Test completado. Tiempo total: %d segundos" % int(tiempo_transcurrido))

func _reset_ui_valores():
	if is_instance_valid(display_tiempo): display_tiempo.text = "0.0 s"
	if is_instance_valid(display_kilos): display_kilos.text = "0.0 Kg"

func _desactivar_controles(bloquear: bool):
	if is_instance_valid(btn_comenzar): btn_comenzar.disabled = bloquear
	if is_instance_valid(input_porcentaje): input_porcentaje.editable = not bloquear
	if is_instance_valid(input_mano): input_mano.disabled = bloquear

func _dibujar_grafica():
	if not is_instance_valid(grafica): return
	datos_grafica.append(peso_received_frame)
	if datos_grafica.size() > max_puntos_grafica:
		datos_grafica.remove_at(0)
		
	grafica.clear_points()
	var ancho_panel = 600.0
	for i in range(datos_grafica.size()):
		var x = i * (ancho_panel / max_puntos_grafica)
		var y = 150.0 - (datos_grafica[i] * 2.0)
		grafica.add_point(Vector2(x, y))

func _decir_voz(texto: String):
	if not ConfigManager.voz_activa: return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH): return
	var vol_android: int = clampi(int(ConfigManager.volumen_voz * 100.0), 0, 100)
	DisplayServer.tts_speak(texto, "", vol_android)
