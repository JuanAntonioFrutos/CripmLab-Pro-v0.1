extends Node

# Bluetooth Global
var mac_objetivo: String = ""
var sensor_confirmado: bool = false

# Persistencia de Datos de Fuerza Máxima entre pantallas
var record_max_izq: float = 0.0
var record_max_der: float = 0.0
var rutinas_entreno: Dictionary = {}
