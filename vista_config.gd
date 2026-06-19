extends VBoxContainer

@onready var check_voz = %CheckVoz
@onready var slider_voz = %SliderVoz
@onready var check_pitidos = %CheckPitidos
@onready var slider_pitidos = %SliderPitidos
@onready var combo_tema = %ComboTema

# Componentes interactivos vinculados
@onready var input_size_titulos = %InputSizeTitulos
@onready var input_size_normal = %InputSizeNormal
@onready var input_size_cargas = %InputSizeCargas

@onready var picker_color_titulos = %PickerColorTitulos
@onready var picker_color_normal = %PickerColorNormal
@onready var picker_color_btn_iniciar = %PickerColorBtnIniciar
@onready var picker_color_btn_parar = %PickerColorBtnParar
@onready var picker_color_btn_guardar = %PickerColorBtnGuardar
@onready var picker_color_grafica = %PickerColorGrafica

func _ready():
	# 1. Cargar valores actuales de Audio y Temas base
	check_voz.button_pressed = ConfigManager.voz_activa
	slider_voz.value = ConfigManager.volumen_voz
	check_pitidos.button_pressed = ConfigManager.pitidos_activos
	slider_pitidos.value = ConfigManager.volumen_pitidos
	
	combo_tema.clear()
	for nombre_tema in ConfigManager.TEMAS.keys():
		combo_tema.add_item(nombre_tema)
		
	for i in range(combo_tema.item_count):
		if combo_tema.get_item_text(i) == ConfigManager.tema_actual:
			combo_tema.selected = i
			break

	# 2. Asignar los valores numéricos y colores actuales al diseño de configuración
	input_size_titulos.value = ConfigManager.font_size_titulos
	input_size_normal.value = ConfigManager.font_size_normal
	input_size_cargas.value = ConfigManager.font_size_cargas
	
	picker_color_titulos.color = ConfigManager.color_texto_titulo
	picker_color_normal.color = ConfigManager.color_texto_normal
	picker_color_btn_iniciar.color = ConfigManager.color_btn_iniciar
	picker_color_btn_parar.color = ConfigManager.color_btn_parar
	picker_color_btn_guardar.color = ConfigManager.color_btn_guardar
	picker_color_grafica.color = ConfigManager.color_linea_grafica

	# 3. Conectar señales básicas
	check_voz.toggled.connect(func(valor): ConfigManager.voz_activa = valor)
	check_pitidos.toggled.connect(func(valor): ConfigManager.pitidos_activos = valor)
	combo_tema.item_selected.connect(_on_tema_seleccionado)
	slider_voz.value_changed.connect(func(valor): ConfigManager.actualizar_volumen_voz(valor))
	slider_pitidos.value_changed.connect(func(valor): ConfigManager.actualizar_volumen_pitidos(valor))

	# 4. Conectar señales de cambio en vivo para estilos personalizados
	input_size_titulos.value_changed.connect(func(valor):
		ConfigManager.font_size_titulos = int(valor)
		ConfigManager.aplicar_estilos_dinamicos(self)
	)
	input_size_normal.value_changed.connect(func(valor):
		ConfigManager.font_size_normal = int(valor)
		ConfigManager.aplicar_estilos_dinamicos(self)
	)
	input_size_cargas.value_changed.connect(func(valor):
		ConfigManager.font_size_cargas = int(valor)
		ConfigManager.aplicar_estilos_dinamicos(self)
	)
	
	picker_color_titulos.color_changed.connect(func(color):
		ConfigManager.color_texto_titulo = color
		ConfigManager.aplicar_estilos_dinamicos(self)
	)
	picker_color_normal.color_changed.connect(func(color):
		ConfigManager.color_texto_normal = color
		ConfigManager.aplicar_estilos_dinamicos(self)
	)
	picker_color_btn_iniciar.color_changed.connect(func(color):
		ConfigManager.color_btn_iniciar = color
		ConfigManager.aplicar_estilos_dinamicos(self)
	)
	picker_color_btn_parar.color_changed.connect(func(color):
		ConfigManager.color_btn_parar = color
		ConfigManager.aplicar_estilos_dinamicos(self)
	)
	picker_color_btn_guardar.color_changed.connect(func(color):
		ConfigManager.color_btn_guardar = color
		ConfigManager.aplicar_estilos_dinamicos(self)
	)
	picker_color_grafica.color_changed.connect(func(color):
		ConfigManager.color_linea_grafica = color
		ConfigManager.aplicar_estilos_dinamicos(self)
	)

	# Forzar una aplicación inicial completa al iniciar
	ConfigManager.aplicar_estilos_dinamicos(self)

func _on_tema_seleccionado(index: int):
	ConfigManager.tema_actual = combo_tema.get_item_text(index)
	var colores = ConfigManager.obtener_colores_tema()
	RenderingServer.set_default_clear_color(colores["fondo"])
	ConfigManager.aplicar_estilos_dinamicos(self)
