extends VBoxContainer

var main_referencia: Node = null
var dispositivos_encontrados: Array = []

@onready var display_kilos = %DisplayKilos
@onready var lista_dispositivos = %ListaDispositivos
@onready var btn_conectar = %BtnConectar
@onready var btn_tarar = %BtnTarar

func inicializar(main_node):
	add_to_group("interfaz_rediseñable")
	_on_estilos_actualizados()
	main_referencia = main_node
	btn_conectar.pressed.connect(_on_conectar)
	btn_tarar.pressed.connect(_on_tarar)
	lista_dispositivos.item_selected.connect(_on_seleccionado)

	# Si ya veníamos conectados de antes, actualizar interfaz
	if RegletasManager.sensor_confirmado:
		btn_conectar.text = "Conectado"
		btn_conectar.add_theme_color_override("font_color", Color("#00e676"))
		lista_dispositivos.visible = false
	else:
		lista_dispositivos.visible = false

func _on_conectar():
	print("Iniciando escaneo BLE...")
	lista_dispositivos.clear()
	dispositivos_encontrados.clear()
	
	# 🌟 CORRECCIÓN 1: Forzamos a que la lista sea visible para el usuario al pulsar escanear
	lista_dispositivos.visible = true
	btn_conectar.text = "Escaneando..."

	if Engine.has_singleton("GodotBluetooth"):
		var ble = Engine.get_singleton("GodotBluetooth")
		print("Singleton encontrado")
		print("Permisos otorgados:")
		print(OS.get_granted_permissions())
		ble.scan()
	else:
		print("GodotBluetooth NO encontrado (Cargando simulación local...)")

func _on_seleccionado(index: int):
	# 🌟 CORRECCIÓN 2: Recuperamos la MAC de los metadatos de forma segura
	var mac_seleccionada = lista_dispositivos.get_item_metadata(index)
	
	if mac_seleccionada == null:
		print("⚠️ Error: El ítem seleccionado no contiene metadatos de MAC.")
		return
		
	RegletasManager.mac_objetivo = mac_seleccionada
	RegletasManager.sensor_confirmado = true
	print("Sensor seleccionado manualmente con éxito: ", mac_seleccionada)

	# Modificación visual de éxito de conexión
	btn_conectar.text = "Conectado"
	btn_conectar.add_theme_color_override("font_color", Color("#00e676"))
	
	# Ocultamos la lista una vez que el usuario ya seleccionó su sensor
	lista_dispositivos.visible = false

func _on_tarar():
	if main_referencia:
		main_referencia.ejecutar_tara()

func _on_bluetooth_log(msg):
	print("BLE RAW -> ", msg)

# Llamado por el script principal cuando entra señal de escáner
func procesar_paquete_bluetooth(mac: String, _payload_hex: String):
	# 🌟 CORRECCIÓN 3: Eliminamos la inyección automática de "Desconocido" para evitar duplicar 
	# los dispositivos que ya introduce 'recibir_nombre_dispositivo'.
	# Solo dejamos el registro en el array de control si no existía.
	if not RegletasManager.sensor_confirmado:
		if not mac in dispositivos_encontrados:
			dispositivos_encontrados.append(mac)

# Llamado automáticamente por el enrutador principal
func actualizar_peso(kilos: float):
	display_kilos.text = "%.1f Kg" % kilos

func recibir_nombre_dispositivo(nombre: String, mac: String):
	if RegletasManager.sensor_confirmado: return
	
	# Buscamos si la dirección MAC ya está en el ItemList para actualizar texto en vez de duplicar
	var ya_existe = false
	for i in range(lista_dispositivos.item_count):
		if lista_dispositivos.get_item_metadata(i) == mac:
			# Si el nombre viene vacío o genérico de primeras y ahora llega el real (ej: IF_B7), lo actualizamos
			var nombre_limpio = nombre if nombre != "" else "Dispositivo BLE"
			lista_dispositivos.set_item_text(i, "%s [%s]" % [nombre_limpio, mac])
			ya_existe = true
			break
			
	if not ya_existe:
		# Añadimos el dispositivo con su Nombre Real y Dirección MAC en una sola línea limpia
		var nombre_final = nombre if nombre != "" else "Dispositivo BLE"
		var indice = lista_dispositivos.add_item("%s [%s]" % [nombre_final, mac])
		
		# 🌟 CRÍTICO: Guardamos la MAC en los metadatos del ítem para recuperarla en '_on_seleccionado'
		lista_dispositivos.set_item_metadata(indice, mac)
		print("[INTERFAZ] Añadido a la lista: ", nombre_final, " -> ", mac)

func _on_estilos_actualizados():
	queue_redraw()
