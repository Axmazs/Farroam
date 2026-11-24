class_name ShipAI
extends Node

signal arrived

var data: ShipData
var active_simulation: ShipSimulation
var flying := false

@onready var mode_2d: ShipSimulation = $Mode2D
@onready var mode_no_map: ShipSimulation = $ModeNoMap
@onready var job = $Job


func initialize(ship_data: ShipData) -> void:
	data = ship_data

	mode_2d.data = data
	mode_no_map.data = data

	mode_2d.arrived.connect(_on_arrived)
	mode_no_map.arrived.connect(_on_arrived)

	active_simulation = mode_2d
	job.initialize(self)


func fly_to(destination: Vector3) -> void:
	if flying:
		active_simulation.stop()

	data.destination = destination
	flying = true
	active_simulation.start()


func set_map_mode(map_open: bool) -> void:
	var next_simulation := mode_2d if map_open else mode_no_map

	if next_simulation == active_simulation:
		return

	active_simulation.stop()
	active_simulation = next_simulation

	if flying:
		active_simulation.start()


func _on_arrived() -> void:
	flying = false
	arrived.emit()
