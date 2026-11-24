class_name Ship
extends Node

@export var data: ShipData

@onready var ai: ShipAI = $ShipAI


func _ready() -> void:
	assert(data != null, "Am Schiff fehlt die ShipData-Ressource.")
	ai.initialize(data)
