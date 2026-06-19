extends VBoxContainer

var main_referencia: Node = null

var test_activo: bool = false
var estado_test: String = "IDLE"
var tiempo_restante: float = 0.0

var intento_actual: int = 1
var max_intentos: int = 3
var mano_seleccionada: String = "Mano Izquierda"

var datos_grafica: Array = []
var max_puntos_grafica: int = 100
var peso_recibido: float = 0.0
var pico_intento_actual: float = 0.0

var segundo_actual_int: int = -1

@onready var label_estado = %LabelEstado
@onready var contenedor_estado = %ContenedorEstado
@onready var display_kilos_max = %DisplayKilosMax
@onready var grafica = %GraficaLineal
@onready var input_traccion = %InputTraccion
@onready var input_descanso = %InputDescanso
@onready var input_intentos = %InputIntentos
@onready var input_mano = %InputMano
@onready var btn_comenzar = %BtnComenzarTest
@onready var btn_parar = %BtnParaTest

@onready var label_max_izq = %LabelMaxIzq
@onready var label_max_der = %LabelMaxDer

func inicializar(main_node):
	add_to_group("interfaz_rediseñable")
	_on_estilos_actualizados()
	main_referencia = main_node
	
	# Desconectar si ya estaba conectado para evitar duplicados seguros
	if btn_comenzar.pressed.is_connected(_on_btn_comenzar_pressed):
		btn_comenzar.pressed.disconnect(_on_btn_comenzar_pressed)
	if btn_parar.pressed.is_connected(_on_btn_parar_pressed):
		btn_parar.pressed.disconnect(_on_btn_parar_pressed)
		
	btn_comenzar.pressed.connect(_on_btn_comenzar_pressed)
	btn_parar.pressed.connect(_on_btn_parar_pressed)
	
	# Valores por defecto en la UI
	input_traccion.value = 5
	input_descanso.value = 180
	input_intentos.value = 3
	
	input_mano.clear()
	input_mano.add_item("Mano Izquierda")
	input_mano.add_item("Mano Derecha")
	input_mano.add_item("Ambas (Alternando)")
	
	_actualizar_pantalla_records()
	_cambiar_estado_sistema("IDLE")

func _on_estilos_actualizados():
	pass

func _process(delta):
	if not test_activo: return
	
	tiempo_restante -= delta
	if tiempo_restante < 0: tiempo_restante = 0
	
	_actualizar_ui_cronometro()
	
	if tiempo_restante <= 0:
		_avanzar_maquina_estados()

# 🌟 FUNCIÓN CORREGIDA: Fuerza el cambio del fondo EXTERIOR y limpia cualquier override local
func _cambiar_estado_sistema(nuevo_estado: String):
	estado_test = nuevo_estado
	
	if not main_referencia or not main_referencia.has_method("cambiar_color_fondo_sistema"):
		return

	# Creamos el estilo base para la tarjeta pequeña del Label
	var estilo_caja = StyleBoxFlat.new()
	estilo_caja.corner_radius_top_left = 10
	estilo_caja.corner_radius_top_right = 10
	estilo_caja.corner_radius_bottom_left = 10
	estilo_caja.corner_radius_bottom_right = 10
	estilo_caja.content_margin_top = 8
	estilo_caja.content_margin_bottom = 8

	match nuevo_estado:
		"IDLE":
			label_estado.text = "LISTO"
			estilo_caja.bg_color = Color("#232329") # Gris oscuro neutro original
			main_referencia.cambiar_color_fondo_sistema("NORMAL")
		"PREPARA":
			var prefijo = _obtener_prefijo_mano()
			label_estado.text = "[%s] ¡PREPARA! %d" % [prefijo, ceil(tiempo_restante)]
			estilo_caja.bg_color = Color("#d35400") # 🟧 Fondo de tarjeta Naranja
			main_referencia.cambiar_color_fondo_sistema("PREPARACION")
		"TRACCION":
			var prefijo = _obtener_prefijo_mano()
			label_estado.text = "[%s] ¡MÁXIMA TRACCIÓN! - %ds" % [prefijo, ceil(tiempo_restante)]
			estilo_caja.bg_color = Color("#c0392b") # 🟥 Fondo de tarjeta Rojo
			main_referencia.cambiar_color_fondo_sistema("TRACCION")
		"DESCANSO":
			label_estado.text = "DESCANSO RECUPERACIÓN: %d:%02d" % [int(tiempo_restante) / 60, int(tiempo_restante) % 60]
			estilo_caja.bg_color = Color("#27ae60") # 🟩 Fondo de tarjeta Verde
			main_referencia.cambiar_color_fondo_sistema("DESCANSO")
		"FINALIZADO":
			label_estado.text = "TEST COMPLETADO"
			estilo_caja.bg_color = Color("#232329")
			main_referencia.cambiar_color_fondo_sistema("NORMAL")

	# Aplicamos el color de fondo de la tarjeta al contenedor
	if is_instance_valid(contenedor_estado):
		contenedor_estado.add_theme_stylebox_override("panel", estilo_caja)

func _on_btn_comenzar_pressed():
	if test_activo: return
	
	intento_actual = 1
	max_intentos = int(input_intentos.value)
	mano_seleccionada = input_mano.get_item_text(input_mano.selected)
	
	test_activo = true
	_desactivar_controles(true)
	
	# Inicia con cuenta atrás de preparación
	tiempo_restante = 5.0 
	_cambiar_estado_sistema("PREPARA")
	_decir_voz("Prepararse")

func _on_btn_parar_pressed():
	if not test_activo: return
	test_activo = false
	_desactivar_controles(false)
	_cambiar_estado_sistema("IDLE")
	_decir_voz("Test cancelado")

func _avanzar_maquina_estados():
	match estado_test:
		"PREPARA":
			tiempo_restante = input_traccion.value
			pico_intento_actual = 0.0
			datos_grafica.clear()
			_cambiar_estado_sistema("TRACCION")
			_decir_voz("Tira")
			
		"TRACCION":
			_guardar_pico_intento()
			
			if intento_actual < max_intentos:
				tiempo_restante = input_descanso.value
				_cambiar_estado_sistema("DESCANSO")
				_decir_voz("Descansa")
			else:
				test_activo = false
				_cambiar_estado_sistema("FINALIZADO")
				_desactivar_controles(false)
				_decir_voz("Test finalizado")
				
		"DESCANSO":
			intento_actual += 1
			tiempo_restante = 5.0
			_cambiar_estado_sistema("PREPARA")
			_decir_voz("Siguiente intento")

func _actualizar_ui_cronometro():
	var seg_actual = ceili(tiempo_restante)
	if seg_actual != segundo_actual_int:
		segundo_actual_int = seg_actual
		_cambiar_estado_sistema(estado_test)
		
		if estado_test == "PREPARA" and seg_actual <= 3 and seg_actual > 0:
			_decir_voz(str(seg_actual))
		elif estado_test == "TRACCION" and seg_actual <= 3 and seg_actual > 0:
			_decir_voz(str(seg_actual))

	if estado_test == "TRACCION":
		_dibujar_grafica()

func _desactivar_controles(bloquear: bool):
	input_traccion.editable = not bloquear
	input_descanso.editable = not bloquear
	input_intentos.editable = not bloquear
	input_mano.disabled = bloquear
	btn_comenzar.disabled = bloquear

func _guardar_pico_intento():
	var prefijo = _obtener_prefijo_mano()
	if prefijo == "IZQ":
		if pico_intento_actual > RegletasManager.record_max_izq:
			RegletasManager.record_max_izq = pico_intento_actual
	else:
		if pico_intento_actual > RegletasManager.record_max_der:
			RegletasManager.record_max_der = pico_intento_actual

	_actualizar_pantalla_records()

func _actualizar_pantalla_records():
	if is_instance_valid(label_max_izq) and is_instance_valid(label_max_der):
		label_max_izq.text = "Max Izq: %.1f Kg" % RegletasManager.record_max_izq
		label_max_der.text = "Max Der: %.1f Kg" % RegletasManager.record_max_der

func _obtener_prefijo_mano() -> String:
	if mano_seleccionada.to_lower().contains("ambas"):
		return "IZQ" if (intento_actual % 2 != 0) else "DER"
	return "IZQ" if mano_seleccionada.to_lower().contains("izquierda") else "DER"

func actualizar_peso(kilos: float):
	peso_recibido = kilos
	display_kilos_max.text = "%.1f Kg" % kilos
	
	if test_activo and estado_test == "TRACCION":
		if kilos > pico_intento_actual:
			pico_intento_actual = kilos

func _dibujar_grafica():
	datos_grafica.append(peso_recibido)
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
