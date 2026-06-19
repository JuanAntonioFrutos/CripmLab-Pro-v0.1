extends VBoxContainer

@onready var selector = %SelectorUsuarios
@onready var input_nombre = %InputNombre
@onready var input_peso = %InputPeso
@onready var input_edad = %InputEdad
@onready var input_altura = %InputAltura
@onready var btn_guardar = %BtnGuardar

func inicializar(_main):
	_actualizar_lista()
	btn_guardar.pressed.connect(_on_guardar)
	selector.item_selected.connect(_on_usuario_seleccionado)
	
	# Cargar datos actuales del manager si existen
	input_nombre.text = UsuarioManager.usuario_actual
	input_peso.value = UsuarioManager.peso_actual

func _actualizar_lista():
	selector.clear()
	var perfiles = UsuarioManager._leer_todos_los_perfiles()
	for p in perfiles.keys():
		selector.add_item(p)

func _on_guardar():
	var nombre = input_nombre.text.strip_edges()
	if nombre == "": return
	
	UsuarioManager.guardar_perfil(nombre, input_peso.value, input_edad.value, input_altura.value)
	_actualizar_lista()
	if VozManager.has_method("decir"): VozManager.decir("Perfil de " + nombre + " actualizado")

func _on_usuario_seleccionado(idx):
	var nombre = selector.get_item_text(idx)
	var perfiles = UsuarioManager._leer_todos_los_perfiles()
	var p = perfiles[nombre]
	
	UsuarioManager.usuario_actual = nombre
	UsuarioManager.peso_actual = p["peso"]
	input_nombre.text = nombre
	input_peso.value = p["peso"]
