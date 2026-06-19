extends Node

# Preferencias de Audio
var voz_activa: bool = true
var pitidos_activos: bool = true
var volumen_voz: float = 1.0     
var volumen_pitidos: float = 0.5 

# Gestión de Temas Visuales
var tema_actual: String = "Cyberpunk"

# --- CONFIGURACIÓN INDEPENDIENTE DE TEXTOS Y COMPONENTES ---
var font_size_titulos: int = 24
var font_size_normal: int = 15
var font_size_cargas: int = 72

var color_texto_titulo: Color = Color("#ffffff")
var color_texto_normal: Color = Color("#e0e0e0")

var color_btn_iniciar: Color = Color("#1b6f3b")
var color_btn_parar: Color = Color("#952d2d")
var color_btn_guardar: Color = Color("#1976d2")
var color_linea_grafica: Color = Color("#10b5f5")

const TEMAS = {
	"Cyberpunk": {
		"fondo": Color("#07070a"),
		"tarjeta": Color("#1a1a1e"),
		"prepara": Color("#ff9100"),  
		"traccion": Color("#ff5252"), 
		"descanso": Color("#00e676")  
	},
	"NeonVibe": {
		"fondo": Color("#0d0221"),
		"tarjeta": Color("#241442"),
		"prepara": Color("#00f0ff"),  
		"traccion": Color("#ff007f"), 
		"descanso": Color("#7000ff")  
	},
	"ClassicGym": {
		"fondo": Color("#121212"),
		"tarjeta": Color("#1e1e1e"),
		"prepara": Color("#fbc02d"),  
		"traccion": Color("#1976d2"), 
		"descanso": Color("#78909c")  
	}
}

func actualizar_volumen_voz(valor: float):
	volumen_voz = valor

func actualizar_volumen_pitidos(valor: float):
	volumen_pitidos = valor
	var db = linear_to_db(valor)
	var master_bus_idx = AudioServer.get_bus_index("Master")
	if master_bus_idx != -1:
		AudioServer.set_bus_volume_db(master_bus_idx, db)
		AudioServer.set_bus_mute(master_bus_idx, valor == 0.0)

func obtener_colores_tema() -> Dictionary:
	return TEMAS.get(tema_actual, TEMAS["Cyberpunk"])

# --- UNIFICADOR DE ESTILOS DINÁMICOS CORREGIDO ---

func aplicar_estilos_dinamicos(escena_nodo: Node):
	var resource_tema = load("res://tema_crimplab.tres") as Theme
	if not resource_tema: 
		print("Error: No se pudo cargar res://tema_crimplab.tres")
		return
	
	# 1. ASIGNACIÓN DE TAMAÑOS DE FUENTE INDEPENDIENTES
	resource_tema.set_font_size("font_size", "Label", font_size_normal)
	resource_tema.set_font_size("font_size", "LabelTitulo", font_size_titulos)
	resource_tema.set_font_size("font_size", "LabelCargaGrande", font_size_cargas)
	
	# 2. ASIGNACIÓN DE COLORES DE TEXTO INDEPENDIENTES
	resource_tema.set_color("font_color", "Label", color_texto_normal)
	resource_tema.set_color("font_color", "LabelTitulo", color_texto_titulo)
	resource_tema.set_color("font_color", "LabelCargaGrande", color_texto_titulo)
	
	# 3. ACTUALIZACIÓN DE BOTONES (Sin tocar la clase base "Button")
	# Esto evita que OptionButton y SpinBox se vuelvan de color azul
	_gestionar_estilo_flat_boton(resource_tema, "BotonIniciar", color_btn_iniciar)
	_gestionar_estilo_flat_boton(resource_tema, "BotonParar", color_btn_parar)
	_gestionar_estilo_flat_boton(resource_tema, "BotonGuardar", color_btn_guardar)
	
	# 4. PROPAGAR CAMBIOS Y RE-RENDERIZAR
	resource_tema.emit_changed()
	
	if escena_nodo and escena_nodo.is_inside_tree():
		var root = escena_nodo.get_tree().root
		root.theme = null
		root.theme = resource_tema
		
		# Notificar a las pantallas activas
		escena_nodo.get_tree().call_group("interfaz_rediseñable", "_on_estilos_actualizados")

# Función auxiliar corregida para inyectar correctamente los StyleBoxFlat
func _gestionar_estilo_flat_boton(tema_res: Theme, nombre_variacion: String, color_base: Color):
	var normal_box = StyleBoxFlat.new()
	normal_box.bg_color = color_base
	normal_box.corner_radius_top_left = 8
	normal_box.corner_radius_top_right = 8
	normal_box.corner_radius_bottom_right = 8
	normal_box.corner_radius_bottom_left = 8
	# Añadimos un pequeño margen interno para que el botón no colapse si pierde tamaño
	normal_box.content_margin_left = 16
	normal_box.content_margin_right = 16
	normal_box.content_margin_top = 8
	normal_box.content_margin_bottom = 8
	
	tema_res.set_stylebox("normal", nombre_variacion, normal_box)
	
	var pressed_box = normal_box.duplicate() as StyleBoxFlat
	pressed_box.bg_color = color_base.darkened(0.2)
	tema_res.set_stylebox("pressed", nombre_variacion, pressed_box)
	
	# Opcional: Color de la fuente dentro de la variación del botón
	tema_res.set_color("font_color", nombre_variacion, Color.WHITE)

# Función auxiliar reescrita para evitar errores de nombres "not found"

		
func _actualizar_estilo_boton(tema_res: Theme, tipo_variacion: String, color_base: Color):
	var flat_style = StyleBoxFlat.new()
	flat_style.bg_color = color_base
	flat_style.corner_radius_top_left = 8
	flat_style.corner_radius_top_right = 8
	flat_style.corner_radius_bottom_right = 8
	flat_style.corner_radius_bottom_left = 8
	tema_res.set_stylebox("normal", tipo_variacion, flat_style)
	
	var pressed_style = flat_style.duplicate()
	pressed_style.bg_color = color_base.darkened(0.2)
	tema_res.set_stylebox("pressed", tipo_variacion, pressed_style)
