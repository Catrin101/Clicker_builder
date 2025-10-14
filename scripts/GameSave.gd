# Archivo: res://GameSave.gd
class_name GameSave
extends Resource

# --- Metadatos ---
@export var version: String
@export var timestamp: int

# --- Datos de Managers ---
@export var player_points: int
@export var grid_data: GridData # Aquí guardaremos el estado de la cuadrícula
@export var stats_data: Dictionary
@export var completion_data: Dictionary
