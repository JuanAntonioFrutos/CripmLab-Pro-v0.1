extends Control

const COLOR_CARD = Color("#1a1a1e")
const COLOR_TEXT_SECONDARY = Color("#8e8e93")

# --- TELEMETRÍA GLOBAL ---
var raw_fuerza: float = 0.0
var valor_tara: float = 0.0
var fuerza_actual: float = 0.0

var vista_activa: Node = null

# --- ESTILOS DE PESTAÑAS (VISTAS) ---
var estilo_pestana_normal: StyleBoxFlat = StyleBoxFlat.new()
var estilo_pestana_activa: StyleBoxFlat = StyleBoxFlat.new()

# Mantienes "Ajustes" en el array para que el sistema sepa que existe la vista
var nombres_vistas = ["En Vivo", "Test Max", "Test Resis", "Entreno", "Historial","Usuario", "Ajustes"]

# Mapeo para instanciar las escenas dinámicamente
var escenas = {
	"En Vivo": preload("res://vista_vivo.tscn"),
	"Test Max": preload("res://vista_max.tscn"),
	"Test Resis": preload("res://vista_resistencia.tscn"),
	"Entreno": preload("res://vista_entreno.tscn"),
	"Historial": preload("res://vista_historial.tscn"),
	"Usuario": preload("res://vista_usuario.tscn"),
	"Ajustes": preload("res://vista_config.tscn")
}

@onready var tabs_container = $%TabsContainer
@onready var panel_vistas = $%PanelVistas
@onready var main_container = $%MainContainer

func _ready():
	OS.request_permissions()
	print("Tiene SCAN:",
		OS.has_feature("android"))
	print(OS.get_granted_permissions())
	print(OS.get_model_name())
	print(OS.get_version())
	if OS.get_name() == "Android":
		var permisos = [
			"android.permission.BLUETOOTH_SCAN",
			"android.permission.BLUETOOTH_CONNECT",
			"android.permission.ACCESS_FINE_LOCATION"
			]

		for p in permisos:
			if !OS.request_permission(p):
				print("No concedido:", p)
			else:
				print("Concedido:", p)
	print("Android:", OS.get_name())

	for s in Engine.get_singleton_list():
		print("Singleton: ", s)
	
	# Estilo del contenedor principal
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = COLOR_CARD
	estilo.corner_radius_top_left = 20
	estilo.corner_radius_top_right = 20
	estilo.corner_radius_bottom_left = 20
	estilo.corner_radius_bottom_right = 20
	main_container.add_theme_stylebox_override("panel", estilo)

	_crear_menu_pestanas()
	_cambiar_vista("En Vivo") # Pantalla por defecto

	# Sincronizar el color de fondo con el tema actual al iniciar la app
	if has_node("/root/ConfigManager"):
		var colores = ConfigManager.obtener_colores_tema()
		RenderingServer.set_default_clear_color(colores["fondo"])
		estilo.bg_color = colores["tarjeta"]

	# Enlace con Plugin Android Java
	if Engine.has_singleton("GodotBluetooth"):
		var ble = Engine.get_singleton("GodotBluetooth")
		ble.connect("bluetooth_log", Callable(self, "_on_bluetooth_data_received"))
	else:
		_activar_simulacion_pc()
		
	# 🌟 NOTA: Hemos eliminado el bloque tts_speak del final de esta función. 
	# Dejamos que Android levante su servicio de voz en segundo plano a su propio ritmo.

func _crear_menu_pestanas():
	# Configurar el molde para pestañas inactivas (Gris oscuro)
	estilo_pestana_normal.bg_color = Color("#232329")
	estilo_pestana_normal.corner_radius_top_left = 8
	estilo_pestana_normal.corner_radius_top_right = 8
	estilo_pestana_normal.corner_radius_bottom_left = 8
	estilo_pestana_normal.corner_radius_bottom_right = 8
	estilo_pestana_normal.content_margin_top = 8
	estilo_pestana_normal.content_margin_bottom = 8

	# Configurar el molde para la pestaña activa (Negro con borde sutil)
	estilo_pestana_activa.bg_color = Color("#111115")
	estilo_pestana_activa.corner_radius_top_left = 8
	estilo_pestana_activa.corner_radius_top_right = 8
	estilo_pestana_activa.corner_radius_bottom_left = 8
	estilo_pestana_activa.corner_radius_bottom_right = 8
	estilo_pestana_activa.content_margin_top = 8
	estilo_pestana_activa.content_margin_bottom = 8
	estilo_pestana_activa.border_width_left = 1
	estilo_pestana_activa.border_width_top = 1
	estilo_pestana_activa.border_width_right = 1
	estilo_pestana_activa.border_width_bottom = 1
	estilo_pestana_activa.border_color = Color("#3a3a42")

	for nombre in nombres_vistas:
		var btn = Button.new()
		btn.flat = false
		btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		
		# Evitamos el recuadro azul de foco de Godot
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		# Configuración individual de tamaños y espacios horizontales
		if nombre == "Ajustes":
			btn.text = "⚙️"
			btn.name = "BtnAjustes"
			btn.add_theme_font_size_override("font_size", 16)
			btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		elif nombre == "Usuario":
			btn.text = "👤"
			btn.name = "BtnUsuario"
			btn.add_theme_font_size_override("font_size", 16)
			btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		else:
			btn.text = nombre
			btn.add_theme_font_size_override("font_size", 12)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
		btn.set_meta("nombre_vista", nombre)
		btn.pressed.connect(func(): _cambiar_vista(btn.get_meta("nombre_vista")))
		tabs_container.add_child(btn)
	


func _cambiar_vista(nombre_vista: String):
	# 1. Resaltar pestaña activa (Tu lógica actual de botones que funciona bien)
	for boton in tabs_container.get_children():
		if boton is Button:
			var es_activa = boton.get_meta("nombre_vista") == nombre_vista
			
			var nombre_b = boton.get_meta("nombre_vista")
			var margen_lateral = 12 if (nombre_b == "Usuario" or nombre_b == "Ajustes") else 6
			
			if es_activa:
				boton.add_theme_color_override("font_color", Color.WHITE)
				var estilo_a = estilo_pestana_activa.duplicate()
				estilo_a.content_margin_left = margen_lateral
				estilo_a.content_margin_right = margen_lateral
				estilo_a.content_margin_top = 8
				estilo_a.content_margin_bottom = 8
				boton.add_theme_stylebox_override("normal", estilo_a)
				boton.add_theme_stylebox_override("hover", estilo_a)
				boton.add_theme_stylebox_override("pressed", estilo_a)
			else:
				boton.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
				var estilo_n = estilo_pestana_normal.duplicate()
				estilo_n.content_margin_left = margen_lateral
				estilo_n.content_margin_right = margen_lateral
				estilo_n.content_margin_top = 8
				estilo_n.content_margin_bottom = 8
				boton.add_theme_stylebox_override("normal", estilo_n)
				boton.add_theme_stylebox_override("hover", estilo_n)
				boton.add_theme_stylebox_override("pressed", estilo_n)

	# 2. Borrar la vista anterior
	if vista_activa:
		vista_activa.queue_free()
		vista_activa = null

	# 🌟 SOLUCIÓN AL ATASCO: Sincronizar el fondo REAL del ConfigManager al limpiar la pantalla
	if has_node("/root/ConfigManager"):
		var colores = ConfigManager.obtener_colores_tema()
		RenderingServer.set_default_clear_color(colores["fondo"])
		# Si tu MainContainer usa un fondo que cambia con el tema, lo restauramos también aquí:
		if main_container.has_theme_stylebox_override("panel"):
			var estilo_actual = main_container.get_theme_stylebox("panel")
			if estilo_actual is StyleBoxFlat:
				estilo_actual.bg_color = colores["tarjeta"] if colores.has("tarjeta") else COLOR_CARD
	else:
		# Fallback seguro por si ejecutas la escena suelta en el PC sin el ConfigManager cargado
		RenderingServer.set_default_clear_color(Color("#121214"))

	# 3. Instanciar la nueva sub-escena modular
	if escenas.has(nombre_vista):
		vista_activa = escenas[nombre_vista].instantiate()
		panel_vistas.add_child(vista_activa)
		
		if vista_activa.has_method("inicializar"):
			vista_activa.inicializar(self)
	else:
		print("⚠️ La vista '%s' aún no está creada o está en desarrollo." % nombre_vista)
		
		
		
func _on_bluetooth_data_received(data_string: String):
	# Evitamos procesar si la cadena viene completamente vacía
	if data_string.is_empty(): return
	
	# Filtro base: Solo nos interesan datos que empiecen con nuestra cabecera de escáner
	if not "SCAN_DATA" in data_string: 
		return
		
	var partes = data_string.split("|")
	if partes.size() < 5: return 

	var nombre_dispositivo = partes[1].strip_edges() 
	var mac = partes[2].strip_edges().to_upper()
	var payload_hex = partes[3].strip_edges()
	
	# Depuración en consola
	print("Procesando -> Nombre: ", nombre_dispositivo, " | MAC: ", mac)

	# Enviamos los datos ordenados a nuestra pestaña en vivo activa
	if vista_activa:
		if vista_activa.has_method("recibir_nombre_dispositivo"):
			vista_activa.call("recibir_nombre_dispositivo", nombre_dispositivo, mac)
		if vista_activa.has_method("procesar_paquete_bluetooth"):
			vista_activa.call("procesar_paquete_bluetooth", mac, payload_hex)

	# Si el usuario ya seleccionó este dispositivo específico, empezamos a calcular el peso
	if sensor_confirmado_global(mac) or (vista_activa and vista_activa.get("sensor_confirmado")):
		if payload_hex.length() >= 52:
			var hex_peso = payload_hex.substr(46, 6)
			raw_fuerza = float(("0x" + hex_peso).hex_to_int())
			_calcular_kilogramos()

func sensor_confirmado_global(mac: String) -> bool:
	return mac == RegletasManager.mac_objetivo

func _calcular_kilogramos():
	var cero_base = valor_tara if valor_tara != 0.0 else 65536.0
	fuerza_actual = (raw_fuerza - cero_base) / 100.0
	if fuerza_actual < 0.0: fuerza_actual = 0.0

	if vista_activa and vista_activa.has_method("actualizar_peso"):
		vista_activa.actualizar_peso(fuerza_actual)

func ejecutar_tara():
	valor_tara = raw_fuerza
	_calcular_kilogramos()

func _activar_simulacion_pc():
	print("💻 Modo Simulación PC Activo.")
	while true:
		await get_tree().create_timer(0.2).timeout
		var fluctuacion = str(65686 + randi() % 20)
		_on_bluetooth_data_received(
	"SCAN_DATA|IF_B7|2A:C0:19:11:24:AC|020106060949465F423714FF00010203112AC0191124AC01001401F4" + fluctuacion + "0000...|-55"
)
# Función global para cambiar el fondo exterior desde cualquier test
func cambiar_color_fondo_sistema(tipo_estado: String):
	if not main_container: return
	
	var estilo_fondo = main_container.get_theme_stylebox("panel")
	if not estilo_fondo is StyleBoxFlat:
		estilo_fondo = StyleBoxFlat.new()
		estilo_fondo.corner_radius_top_left = 20
		estilo_fondo.corner_radius_top_right = 20
		estilo_fondo.corner_radius_bottom_left = 20
		estilo_fondo.corner_radius_bottom_right = 20
	
	# Configuramos los colores de fondo exteriores y sus bordes como en tus fotos:
	match tipo_estado:
		"PREPARACION": # 🟧 Cuenta atrás (Naranja)
			estilo_fondo.bg_color = Color("#2a1a08") # Fondo oscuro anaranjado
			estilo_fondo.border_width_left = 3
			estilo_fondo.border_width_top = 3
			estilo_fondo.border_width_right = 3
			estilo_fondo.border_width_bottom = 3
			estilo_fondo.border_color = Color("#e67e22") # Borde naranja brillante
			
		"TRACCION": # 🟥 Máxima fuerza / Tensión (Rojo)
			estilo_fondo.bg_color = Color("#2a0808") # Fondo oscuro rojizo
			estilo_fondo.border_width_left = 3
			estilo_fondo.border_width_top = 3
			estilo_fondo.border_width_right = 3
			estilo_fondo.border_width_bottom = 3
			estilo_fondo.border_color = Color("#e74c3c") # Borde rojo brillante
			
		"DESCANSO": # 🟩 Recuperación (Verde)
			estilo_fondo.bg_color = Color("#082a10") # Fondo oscuro verdoso
			estilo_fondo.border_width_left = 3
			estilo_fondo.border_width_top = 3
			estilo_fondo.border_width_right = 3
			estilo_fondo.border_width_bottom = 3
			estilo_fondo.border_color = Color("#2ecc71") # Borde verde brillante
			
		"NORMAL", "IDLE": # ⬛ Estado base por defecto
			estilo_fondo.border_width_left = 0
			estilo_fondo.border_width_top = 0
			estilo_fondo.border_width_right = 0
			estilo_fondo.border_width_bottom = 0
			if has_node("/root/ConfigManager"):
				var colores = ConfigManager.obtener_colores_tema()
				estilo_fondo.bg_color = colores["tarjeta"] if colores.has("tarjeta") else COLOR_CARD
			else:
				estilo_fondo.bg_color = COLOR_CARD
				
	main_container.add_theme_stylebox_override("panel", estilo_fondo)
